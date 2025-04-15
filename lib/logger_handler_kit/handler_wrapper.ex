defmodule LoggerHandlerKit.HandlerWrapper do
  @moduledoc """
  Logger Handler which wraps another handler to make it more testable.

  Logger handlers can be annoying to test for a number of reasons:

  1. If they encounter an error, they are detached instead of crashing, which
  makes it harder to understand what's going on, as the test failure will not
  report the actual error.
  2. Once OTP gets involved, logger handlers might find
  themselves executing in exotic parts of the system. This makes it difficult
  for tests to know when to proceed with assertions.

  `HandlerWrapper` expects the following configuration keys:
  * `test_pid` – PID of a test process.
  * `ref` – a reference to accompany messages it will send to the test process.
  * `handler_module` – a handler module to wrap.
  * `inside_config` – a config to pass to the wrapped handler.

  Whenever the `log/2` callback is invoked, the wrapper handler will pass the
  log event to the wrapped module, catch any error if needed, and once finished,
  send a `{ref, :log_call_completed}` or `{ref, {:handler_error, {kind, reason,
  __STACKTRACE__}}}` message to the test process.

  `HandlerWrapper` is a fairly low level part of the toolbox, so before using
  it, check out `LoggerHandlerKit.Arrange.add_handler/4` and
  `LoggerHandlerKit.Assert.assert_logged/1`.

  ## Example

  ```elixir
  iex(2)> ref = make_ref()
  #Reference<0.3804490001.995622913.186390>
  iex(3)>     :logger.add_handler(:wrapped_handler, LoggerHandlerKit.HandlerWrapper, %{
  ...(3)>       config: %{test_pid: self(), ref: ref, handler_module: :logger_std_h, inside_config: %{}},
  ...(3)>       formatter: Logger.default_formatter()
  ...(3)>     })
  :ok
  iex(4)> Logger.info("Hello!")

  18:27:38.096 [info] Hello!

  18:27:38.096 [info] Hello!
  :ok
  iex(5)> receive do msg -> msg end
  {#Reference<0.3804490001.995622913.186390>, :log_call_completed}
  ```
  """

  @behaviour :logger_handler

  @impl :logger_handler
  def adding_handler(config) do
    unwrapped = unwrap_config(config)
    Code.ensure_loaded!(unwrapped.module)

    if function_exported?(unwrapped.module, :adding_handler, 1) do
      {:ok, %{config: inside_config}} = unwrapped.module.adding_handler(unwrapped)
      {:ok, put_in(config, [:config, :inside_config], inside_config)}
    else
      {:ok, config}
    end
  end

  @impl :logger_handler
  def log(log_event, %{config: %{test_pid: test_pid, ref: ref}} = config) do
    config
    |> unwrap_config()
    |> then(& &1.module.log(log_event, &1))
  catch
    kind, reason ->
      send(test_pid, {ref, {:handler_error, {kind, reason, __STACKTRACE__}}})
  else
    _ -> send(test_pid, {ref, :log_call_completed})
  end

  @impl :logger_handler
  def removing_handler(config) do
    unwrapped = unwrap_config(config)

    if function_exported?(unwrapped.module, :removing_handler, 1) do
      unwrapped.module.removing_handler(unwrapped)
    end
  end

  @impl :logger_handler
  def changing_config(set_or_update, old_config, new_config) do
    old_unwrapped = unwrap_config(old_config)
    new_unwrapped = unwrap_config(new_config)

    if function_exported?(old_unwrapped.module, :changing_config, 3) do
      with {:ok, %{config: inside_config}} <-
             old_unwrapped.module.changing_config(set_or_update, old_unwrapped, new_unwrapped) do
        {:ok, put_in(new_config, [:config, :inside_config], inside_config)}
      end
    end

    {:ok, new_config}
  end

  defp unwrap_config(
         %{config: %{handler_module: handler_module, inside_config: inside_config}} = config
       ) do
    %{config | config: inside_config, module: handler_module}
  end
end
