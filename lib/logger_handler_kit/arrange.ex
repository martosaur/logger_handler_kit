defmodule LoggerHandlerKit.Arrange do
  @moduledoc """
  Functions that help set up logger handler tests.
  """

  @doc """
  Replace global logger translator with per-handler ones, so that each test can configure it independently.

  Normally, `handle_otp_reports` and `handle_sasl_reports` are global configuration
  options, and changing them in tests is sufficient to make the tests sync.
  However, there is a workaround! In reality, both options are read at startup
  and passed to the `logger_translator` filter, which Elixir Logger attaches as a
  primary filter. We can detach this primary filter and reattach it
  to each logger handler independently. This way, each handler can take advantage of
  different translator configurations.

  This function is designed to be run as a test setup, and it does exactly that. It detaches
  the global translator filter and attaches it to each existing handler.

  ```elixir
  defmodule LoggerHandlerKit.DefaultLoggerTest do
    use ExUnit.Case, async: true

    setup_all {LoggerHandlerKit.Arrange, :ensure_per_handler_translation}
    ...
  end
  ```

  > #### Exception {: .warning}
  >
  > Not all handlers will get a personal translator. Attaching logger translator to a logger handler can sometimes lead to
  > surprising results because of the way logger filters work. If a handler has `filter_default: :stop` in configuration, it
  > effectively drops all events by default and expects filters to explicitly tell which events they want through. Logger
  > Translator follows a different paradigm, it blocks things that it wants to be blocked and happily allows everything else.
  > When paired, a conservative handler and a underzelous filter will result in handler receiving events it didn't expect. To
  > mitigate this, we only attach translator to handlers with `filter_default: :log`
  """
  def ensure_per_handler_translation(_context) do
    case get_in(:logger.get_primary_config(), [:filters, :logger_translator]) do
      nil ->
        :ok

      filter ->
        # Logger translator won't play nicely with handlers that have
        # filter_default: :stop, as they would always allow translated events
        for %{id: handler_id, filter_default: :log} <- :logger.get_handler_config() do
          :logger.add_handler_filter(handler_id, :logger_translator, filter)
        end

        ExUnit.Callbacks.on_exit(fn ->
          :logger.add_primary_filter(:logger_translator, filter)
        end)
    end

    :logger.remove_primary_filter(:logger_translator)
  end

  @ownership_server {:global, __MODULE__.OwnershipServer}

  @doc """
  Attaches a logger handler with individual translation and ownership filters.

  ### Arguments

  * `handler_id` is an id that will be used for handler. A good idea is to use a test name or a test module.

  * `handler_module` a handler module that we want to attach. For example, `:logger_std_h` or `Sentry.LoggerHandler`.

  * `config` this is a _handler config_. The one that `handler_module` defines. A small one, of `:term()` type.

  * `big_config_override` is a map that will be merged into _handler config_. But a different one, 
  the one of `:logger_handler.config()` type. This is also the place to put 
  `handle_otp_reports` and `handle_sasl_reports` options, they will be passed to the 
  translator. Finally, `share_ownership_with` option used by `ownership_filter/2` also belongs here.

  ### Return

  The function returns a two element tuple. The first element is a map that contains 
  `handler_id` and `handler_ref`. It can be merged into the test context. The second 
  element is an anonymous function that detaches the handler. Drop it into 
  `ExUnit.Callbacks.on_exit/1` callback.

  The `handler_module` is not attached as-is. Instead, it is wrapped in `LoggerHandlerKit.HandlerWrapper`. 
  Every time a handlers' `c::logger_handler.log/2` callback is invoked, it sends a message to the 
  test process which can be received with `LoggerHandlerKit.Assert.assert_logged/1` function.

  ## Example

  ```elixir
  setup %{test: test} = context do
    {context, on_exit} =
      LoggerHandlerKit.Arrange.add_handler(
        test,
        :logger_std_h,
        %{},
        %{formatter: Logger.default_formatter(), level: :debug}
      )

    on_exit(on_exit)
    context
  end
  ```
  """
  @spec add_handler(:logger_handler.id(), module(), term(), :logger_handler.config() | map()) ::
          {%{handler_id: :logger_handler.id(), handler_ref: reference()}, (-> term())}
  def add_handler(
        handler_id,
        handler_module,
        config,
        big_config_override \\ %{}
      ) do
    ref = make_ref()

    NimbleOwnership.get_and_update(
      @ownership_server,
      self(),
      handler_id,
      fn nil ->
        {nil, %{}}
      end
    )

    big_handler_config = %{
      config: %{
        handler_module: handler_module,
        inside_config: config,
        test_pid: self(),
        ref: ref
      },
      filters: [
        ownership_filter:
          {&ownership_filter/2,
           %{
             handler_id: handler_id,
             test_pid: self(),
             share_ownership_with:
               Map.get(big_config_override, :share_ownership_with, [{:global, Mox.Server}])
           }},
        logger_translator:
          {&Logger.Utils.translator/2,
           %{
             otp: Map.get(big_config_override, :handle_otp_reports, true),
             sasl: Map.get(big_config_override, :handle_sasl_reports, false),
             translators: [
               {Plug.Cowboy.Translator, :translate},
               {Logger.Translator, :translate}
             ]
           }}
      ]
    }

    :logger.add_handler(
      handler_id,
      LoggerHandlerKit.HandlerWrapper,
      Map.merge(big_handler_config, big_config_override)
    )

    on_exit = fn -> :logger.remove_handler(handler_id) end
    context = %{handler_ref: ref, handler_id: handler_id}
    {context, on_exit}
  end

  @doc false
  def start_link_ownership do
    case NimbleOwnership.start_link(name: @ownership_server) do
      {:error, {:already_started, _}} -> :ignore
      other -> other
    end
  end

  @doc """
  Ownership filter drops all events that do not have access to the logger handler attached by `add_handler/4`. This is one of the main things that makes async tests possible.

  Ownership filter is built with `NimbleOwnership` mechanism, the same that powers `Mox`, 
  `Req`, etc. For the most part, caller tracking is enough to correctly propagate 
  ownership information across processes. However, in some cases the logging process is 
  completely detached from the originating process. In this case, ownership filter will 
  check `pid` key in metadata, and if _that_ pid has access to the handler, it will 
  allow it and ask all ownership servers specified in `share_ownership_with` option to do the same.

  By default, `share_ownership_with` only includes `Mox` server (`{:global, Mox.Server}`)
  """
  def ownership_filter(log_event, %{
        handler_id: handler_id,
        share_ownership_with: ownership_servers
      }) do
    callers = Process.get(:"$callers") || []

    meta_pids =
      [
        # A lot of OTP reports have original pid under this key
        get_in(log_event, [:meta, :pid]),
        # In Bandit Plug error, we can fetch thoughtfully put test pid from the `conn` metadata
        get_in(log_event, [:meta, :plug, Access.elem(1), :test_pid]),
        # In Cowboy/Ranch reports, `conn` is also available albeit deeply, painfully nested
        maybe_test_pid_from_ranch_report(log_event)
      ]

    @ownership_server
    |> NimbleOwnership.fetch_owner([self() | callers], handler_id)
    |> case do
      {:ok, _owner_id} ->
        log_event

      _ ->
        case NimbleOwnership.fetch_owner(@ownership_server, meta_pids, handler_id) do
          {:ok, owner_pid} ->
            for server <- ownership_servers do
              with server when not is_nil(server) <-
                     GenServer.whereis(server) do
                for {key, _} <- NimbleOwnership.get_owned(server, owner_pid, %{}) do
                  NimbleOwnership.allow(server, owner_pid, self(), key)
                end
              end
            end

            log_event

          _ ->
            :stop
        end
    end
  end

  @doc """
  Give a particular process access to a logger handler attached by `add_handler/4`.

  It shouldn't be necessary when using `LoggerHandlerKit.Act` functions, but for custom cases you might need it.

  > #### Remember! {: .tip}
  >
  > In a lot of cases, [caller tracking](`m:Task#module-ancestor-and-caller-tracking`) is enough to automatically propagate ownership information. Use it! 
  """
  def allow(owner_pid, pid, handler_id) do
    NimbleOwnership.allow(@ownership_server, owner_pid, pid, handler_id)
  end

  defp maybe_test_pid_from_ranch_report(%{
         msg: {:report, %{args: [_, _, _, _, {{_, {_, _, [_, %{test_pid: pid} | _]}}, _} | _]}}
       }) do
    pid
  end

  defp maybe_test_pid_from_ranch_report(_), do: nil
end
