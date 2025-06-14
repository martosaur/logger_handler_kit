defmodule LoggerHandlerKit.Act do
  @moduledoc """
  Functions that trigger log events.

  The main purpose of these functions is to serve as inspiration and examples of
  test cases. They should be usable directly, but users are expected to go beyond them
  sooner rather than later. This is also the reason why they are not customizable
  and not DRY. Ultimately, you should be able to understand what's going on by looking at
  the source code with minimal jumping throughout the code base.

  Each function represents a case of interest, potentially with different flavors to 
  highlight various cases.

  The functions are divided into four groups: Basic, OTP, SASL and Metadata.

  ## Basic

  These cases focus on log messages a logger handler might encounter. For all cases 
  here, the logger handler will execute in the same process as the test. The complexity 
  comes from the diversity of data types. It's a good idea to make sure your logger 
  handler can handle and format all of these.

  ## OTP

  These cases focus on reports that become relevant once OTP is involved. Consequently, the 
  process where logger handler is called is likely different from the test process, which 
  makes test setup more involved and makes ownership important. This is also when Logger 
  Translator becomes relevant, as a lot of OTP errors originate in Erlang and Elixir translates 
  them to look more familiar.

  Most of the time, the flow of these logs is governed by the `handle_otp_reports` [Logger
  option](`Logger#module-boot-configuration`) (enabled by default).

  A lot of handlers choose to give GenServer errors special treatment, so these 
  cases are a good way to generate some samples.

  ## SASL

  What are SASL logs? Whatever they were, they aren't anymore. [The concept was
  deprecated](https://www.erlang.org/doc/apps/sasl/error_logging.html) in Erlang/OTP 21.
  So for Elixir, SASL logs are the logs that will be skipped if the `handle_sasl_reports`
  configuration option is set to `false`, which are all logs which domain matches `[:otp, :sasl | _]`
  pattern.

  In real life, SASL logs look like reports from supervisors about things that you 
  would expect: child process restarts and such. They are skipped by Elixir by 
  default, but a thorough handler might have an interest in them.

  ## Metadata

  These cases focus on challenges that arise from metadata.
  """

  import ExUnit.Assertions

  @doc """
  The most basic and perhaps most common log message is a simple [string](`String`) passed to one of the `Logger` functions:

  ```elixir
  Logger.info("Hello World")
  ```

  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "string message", %{handler_ref: ref} do
    LoggerHandlerKit.Act.string_message()
    LoggerHandlerKit.Assert.assert_logged(ref)
    
    # handler-specific assertions
  end
  ```

  ### Example Log Event

  ```elixir
  %{
    meta: %{
      pid: #PID<0.218.0>,
      time: 1744679377402910,
      gl: #PID<0.69.0>,
      domain: [:elixir]
    },
    msg: {:string, "Hello World"},
    level: :info
  }
  ```

  <!-- tabs-close -->

  """
  @doc group: "Basic"
  def string_message(), do: Logger.bare_log(:info, "Hello World")

  @doc """
  [Charlists](`e:elixir:binaries-strings-and-charlists.html#charlists`) can be passed to `Logger` functions:

  ```elixir
  Logger.info(~c"Hello world")
  ```

  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "charlist message", %{handler_ref: ref} do
    LoggerHandlerKit.Act.charlist_message()
    LoggerHandlerKit.Assert.assert_logged(ref)
    
    # handler-specific assertions
  end
  ```

  ### Example Log Event

  ```elixir
  %{
    meta: %{
      pid: #PID<0.205.0>,
      time: 1744680216246655,
      gl: #PID<0.69.0>,
      domain: [:elixir]
    },
    msg: {:string, ~c"Hello World"},
    level: :info
  }
  ```

  <!-- tabs-close -->

  """
  @doc group: "Basic"
  def charlist_message(), do: Logger.bare_log(:info, ~c"Hello World")

  @doc """
  [Chardata](`m:IO#module-chardata`) is another tricky type that can be passed directly to the `Logger`.

  Chardata is an arbitrarily nested and potentially **improper** list.

  ```elixir
  Logger.info([?H, ["ello", []], 32 | ~c"World"])
  ```
  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "improper chardata message", %{handler_ref: ref} do
    LoggerHandlerKit.Act.chardata_message(:improper)
    LoggerHandlerKit.Assert.assert_logged(ref)
    
    # handler-specific assertions
  end
  ```

  ### Example Log Event

  ```elixir
  %{
    meta: %{
      pid: #PID<0.205.0>,
      time: 1744681993743465,
      gl: #PID<0.69.0>,
      domain: [:elixir]
    },
    msg: {:string, [72, ["ello", []], 32, 87, 111, 114, 108, 100]},
    level: :info
  }
  ```

  <!-- tabs-close -->

  """
  @doc group: "Basic"
  @spec chardata_message(:proper | :improper) :: :ok
  def chardata_message(flavor \\ :proper)
  def chardata_message(:proper), do: Logger.bare_log(:info, [?H, ["ello", []], 32, ~c"World"])
  def chardata_message(:improper), do: Logger.bare_log(:info, [?H, ["ello", []], 32 | ~c"World"])

  @doc """
  [Keyword lists](`Keyword`) can be passed to the `Logger`, and in this case we call it a [report](https://www.erlang.org/doc/apps/kernel/logger_chapter.html#log-message).

  ```elixir
  Logger.info([hello: "world"])
  ```
  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "keyword report", %{handler_ref: ref} do
    LoggerHandlerKit.Act.keyword_report()
    LoggerHandlerKit.Assert.assert_logged(ref)
    
    # handler-specific assertions
  end
  ```

  ### Example Log Event

  ```elixir
  %{
    meta: %{
      pid: #PID<0.191.0>,
      time: 1744682416540252,
      gl: #PID<0.69.0>,
      domain: [:elixir]
    },
    msg: {:report, [hello: "world"]},
    level: :info
  }
  ```

  <!-- tabs-close -->
  """
  @doc group: "Basic"
  def keyword_report(), do: Logger.bare_log(:info, hello: "world")

  @doc """
  A `Map` can be passed to the `Logger`, and in this case we call it a [report](https://www.erlang.org/doc/apps/kernel/logger_chapter.html#log-message).

  ```elixir
  Logger.info(%{hello: "world"})
  ```

  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "map report", %{handler_ref: ref} do
    LoggerHandlerKit.Act.map_report()
    LoggerHandlerKit.Assert.assert_logged(ref)
    
    # handler-specific assertions
  end
  ```

  ### Example Log Event

  ```elixir
  %{
    meta: %{
      pid: #PID<0.191.0>,
      time: 1744683131714605,
      gl: #PID<0.69.0>,
      domain: [:elixir]
    },
    msg: {:report, %{hello: "world"}},
    level: :info
  }
  ```

  <!-- tabs-close -->
  """
  @doc group: "Basic"
  def map_report(), do: Logger.bare_log(:info, %{hello: "world"})

  @doc """
  Structs are technically maps, but they [do not inherit any of the protocols](`e:elixir:structs.html#structs-are-bare-maps-underneath`)

  Famously, the lack of protocol implementation is what makes it hard to dump structs to JSON.

  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "struct report", %{handler_ref: ref} do
    LoggerHandlerKit.Act.struct_report()
    LoggerHandlerKit.Assert.assert_logged(ref)

    # handler-specific assertions
  end
  ```

  ### Example Log Event

  ```elixir
  %{
    meta: %{
      pid: #PID<0.204.0>,
      time: 1744768094816278,
      gl: #PID<0.69.0>,
      domain: [:elixir]
    },
    msg: {:report, %LoggerHandlerKit.FakeStruct{hello: "world"}},
    level: :info
  }
  ```

  <!-- tabs-close -->
  """
  @doc group: "Basic"
  def struct_report() do
    Logger.bare_log(:info, %LoggerHandlerKit.FakeStruct{hello: "world"})
  end

  @doc """
  [IO format with data](https://www.erlang.org/doc/apps/stdlib/io.html#fwrite/3) is 
  an exotic type which exists beyond the string or report categorization.

  IO format is an Erlang term, and in the Elixir world we almost never 
  encounter it. However, no Erlang thing is truly foreign, so handlers must be
  prepared for it.

  ```elixir
  :logger.info("Hello ~ts", ["World"])
  ```

  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "io format", %{handler_ref: ref} do
    LoggerHandlerKit.Act.io_format()
    LoggerHandlerKit.Assert.assert_logged(ref)

    # handler-specific assertions
  end
  ```

  ### Example Log Event

  ```elixir
  %{
    meta: %{pid: #PID<0.204.0>, time: 1744766862567895, gl: #PID<0.69.0>},
    msg: {"Hello ~ts", ["World"]},
    level: :info
  }
  ```

  <!-- tabs-close -->
  """
  @doc group: "Basic"
  def io_format(), do: :logger.log(:info, "Hello ~ts", ["World"])

  @doc """
  Sometimes, errors are handled and reported as unhandled using [`crash_reason` metadata](guides/unhandled.md#crash_reason-metadata).

  ```elixir
  try do
    raise "oops"
  rescue
    exception -> Logger.error("Something went wrong", crash_reason: {exception, __STACKTRACE__})
  end
  ```

  Developers face a tough choice here: on the one hand, they have both error and
  stacktrace that are perfectly formattable with `Exception.format/3`. On the
  other hand, the user provided an explicit log message. 

  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "log with exception as crash reason", %{handler_ref: ref} do
    LoggerHandlerKit.Act.log_with_crash_reason(:exception)
    LoggerHandlerKit.Assert.assert_logged(ref)

    # handler-specific assertions
  end
  ```

  ### Example Log Event

  ```elixir
  %{
    meta: %{
      pid: #PID<0.204.0>,
      time: 1749943344608173,
      gl: #PID<0.69.0>,
      domain: [:elixir],
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Act, :log_with_crash_reason, 1,
          [
            file: ~c"lib/logger_handler_kit/act.ex",
            line: 531,
            error_info: %{module: Exception}
          ]},
         {LoggerHandlerKit.DefaultLoggerTest,
          :"test Basic log with crash reason: exception", 1,
          [file: ~c"test/default_logger_test.exs", line: 97]},
         {ExUnit.Runner, :exec_test, 2,
          [file: ~c"lib/ex_unit/runner.ex", line: 522]},
         {ExUnit.CaptureLog, :with_log, 2,
          [file: ~c"lib/ex_unit/capture_log.ex", line: 117]},
         {ExUnit.Runner, :"-maybe_capture_log/3-fun-0-", 3,
          [file: ~c"lib/ex_unit/runner.ex", line: 471]},
         {:timer, :tc, 2, [file: ~c"timer.erl", line: 595]},
         {ExUnit.Runner, :"-spawn_test_monitor/4-fun-1-", 6,
          [file: ~c"lib/ex_unit/runner.ex", line: 444]}
       ]}
    },
    msg: {:string, "Handled Exception"},
    level: :error
  }
  ```

  <!-- tabs-close -->
  """
  @doc group: "Basic"
  @spec log_with_crash_reason(:exception | :exit | :throw) :: :ok
  def log_with_crash_reason(:exception) do
    raise "oops"
  rescue
    exception ->
      Logger.bare_log(:error, "Handled Exception", crash_reason: {exception, __STACKTRACE__})
  end

  def log_with_crash_reason(:throw) do
    throw("catch!")
  catch
    :throw, value ->
      Logger.bare_log(:error, "Caught", crash_reason: {{:nocatch, value}, __STACKTRACE__})
  end

  def log_with_crash_reason(:exit) do
    exit("i quit")
  catch
    :exit, value ->
      Logger.bare_log(:error, "Exited", crash_reason: {value, __STACKTRACE__})
  end

  @doc """
  `GenServer` crash is a very common error message. So common, in fact, that a lot of 
  handlers put additional effort into extracting useful information from GenServer reports, 
  such as process name, labels, and client information. Before Elixir 1.19, that was 
  pretty hard to do as `Logger.Translator` would replace the structured report with an 
  unstructured string, but with 1.19 the reports survive translation.

  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "genserver crash exception", %{handler_ref: ref} do
    LoggerHandlerKit.Act.genserver_crash(:exception)
    LoggerHandlerKit.Assert.assert_logged(ref)
    
    # handler-specific assertions
  end
  ```

  ### Example Log Event (< 1.19)

  ```elixir
  %{
    meta: %{
      error_logger: %{tag: :error, report_cb: &:gen_server.format_log/1},
      line: 2646,
      pid: #PID<0.316.0>,
      time: 1744685313255062,
      file: ~c"gen_server.erl",
      gl: #PID<0.69.0>,
      domain: [:otp],
      mfa: {:gen_server, :error_info, 8},
      report_cb: &:gen_server.format_log/2,
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Act, :"-genserver_crash/0-fun-0-", 0,
          [
            file: ~c"lib/logger_handler_kit/act.ex",
            line: 319,
            error_info: %{module: Exception}
          ]},
         {:gen_server, :try_handle_call, 4,
          [file: ~c"gen_server.erl", line: 2381]},
         {:gen_server, :handle_msg, 6, [file: ~c"gen_server.erl", line: 2410]},
         {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 329]}
       ]}
    },
    msg: {:string,
     [
       [
         "GenServer ",
         "#PID<0.316.0>",
         " terminating",
         [
           [10 | "** (RuntimeError) oops"],
           ["\n    " |
            "(logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:319: anonymous fn/0 in LoggerHandlerKit.Act.genserver_crash/0"],
           ["\n    " |
            "(stdlib 6.2.1) gen_server.erl:2381: :gen_server.try_handle_call/4"],
           ["\n    " |
            "(stdlib 6.2.1) gen_server.erl:2410: :gen_server.handle_msg/6"],
           ["\n    " |
            "(stdlib 6.2.1) proc_lib.erl:329: :proc_lib.init_p_do_apply/3"]
         ],
         [],
         "\nLast message",
         [" (from ", "#PID<0.307.0>", ")"],
         ": ",
         "{:run, #Function<0.66655897/0 in LoggerHandlerKit.Act.genserver_crash/0>}"
       ],
       "\nState: ",
       "nil",
       "\nClient ",
       "#PID<0.307.0>",
       " is alive\n",
       ["\n    " | "(stdlib 6.2.1) gen.erl:260: :gen.do_call/4"],
       ["\n    " | "(elixir 1.18.3) lib/gen_server.ex:1125: GenServer.call/3"],
       ["\n    " |
        "(logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:319: LoggerHandlerKit.Act.genserver_crash/0"],
       ["\n    " |
        "test/default_logger_test.exs:85: LoggerHandlerKit.DefaultLoggerTest.\"test Advanced genserver crash\"/1"],
       ["\n    " |
        "(ex_unit 1.18.3) lib/ex_unit/runner.ex:511: ExUnit.Runner.exec_test/2"],
       ["\n    " |
        "(ex_unit 1.18.3) lib/ex_unit/capture_log.ex:113: ExUnit.CaptureLog.with_log/2"],
       ["\n    " |
        "(ex_unit 1.18.3) lib/ex_unit/runner.ex:460: anonymous fn/3 in ExUnit.Runner.maybe_capture_log/3"],
       ["\n    " | "(stdlib 6.2.1) timer.erl:595: :timer.tc/2"],
       ["\n    " |
        "(ex_unit 1.18.3) lib/ex_unit/runner.ex:433: anonymous fn/6 in ExUnit.Runner.spawn_test_monitor/4"]
     ]},
    level: :error
  }
  ```

  ### Example Log Event (1.19+)

  ```elixir
  %{
    meta: %{
      error_logger: %{tag: :error, report_cb: &:gen_server.format_log/1},
      line: 2646,
      pid: #PID<0.203.0>,
      time: 1744684762852118,
      file: ~c"gen_server.erl",
      gl: #PID<0.69.0>,
      domain: [:otp],
      report_cb: &Logger.Utils.translated_cb/1,
      mfa: {:gen_server, :error_info, 8},
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Act, :"-genserver_crash/0-fun-0-", 0,
          [
            file: ~c"lib/logger_handler_kit/act.ex",
            line: 246,
            error_info: %{module: Exception}
          ]},
         {:gen_server, :try_handle_call, 4,
          [file: ~c"gen_server.erl", line: 2381]},
         {:gen_server, :handle_msg, 6, [file: ~c"gen_server.erl", line: 2410]},
         {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 329]}
       ]}
    },
    msg: {:report,
     %{
       label: {:gen_server, :terminate},
       name: #PID<0.203.0>,
       reason: {%RuntimeError{message: "oops"},
        [
          {LoggerHandlerKit.Act, :"-genserver_crash/0-fun-0-", 0,
           [
             file: ~c"lib/logger_handler_kit/act.ex",
             line: 246,
             error_info: %{module: Exception}
           ]},
          {:gen_server, :try_handle_call, 4,
           [file: ~c"gen_server.erl", line: 2381]},
          {:gen_server, :handle_msg, 6, [file: ~c"gen_server.erl", line: 2410]},
          {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 329]}
        ]},
       log: [],
       state: nil,
       client_info: {#PID<0.192.0>,
        {#PID<0.192.0>,
         [
           {:gen, :do_call, 4, [file: ~c"gen.erl", line: 260]},
           {GenServer, :call, 3, [file: ~c"lib/gen_server.ex", line: 1139]},
           {LoggerHandlerKit.Act, :genserver_crash, 0,
            [file: ~c"lib/logger_handler_kit/act.ex", line: 246]},
           {LoggerHandlerKit.DefaultLoggerTest, :"test Advanced genserver crash",
            1, [file: ~c"test/default_logger_test.exs", line: 85]},
           {ExUnit.Runner, :exec_test, 2,
            [file: ~c"lib/ex_unit/runner.ex", line: 515]},
           {ExUnit.CaptureLog, :with_log, 2,
            [file: ~c"lib/ex_unit/capture_log.ex", line: 117]},
           {ExUnit.Runner, :"-maybe_capture_log/3-fun-0-", 3,
            [file: ~c"lib/ex_unit/runner.ex", line: 464]},
           {:timer, :tc, 2, [file: ~c"timer.erl", line: 595]},
           {ExUnit.Runner, :"-spawn_test_monitor/4-fun-1-", 6,
            [file: ~c"lib/ex_unit/runner.ex", line: 437]}
         ]}},
       last_message: {:run,
        #Function<0.66655897/0 in LoggerHandlerKit.Act.genserver_crash/0>},
       process_label: :undefined,
       elixir_translation: [ ... ]
     }},
    level: :error
  }
  ```

  <!-- tabs-close -->
  """
  @doc group: "OTP"
  @spec genserver_crash(
          :exception
          | :exit
          | :exit_with_struct
          | :throw
          | :local_name
          | :global_name
          | :process_label
          | :named_client
          | :dead_client
          | :no_client
        ) :: :ok
  def genserver_crash(flavor \\ :exception)

  def genserver_crash(:exception) do
    {:ok, pid} = LoggerHandlerKit.GenServer.start(nil)
    GenServer.call(pid, {:run, fn -> raise "oops" end})
  catch
    :exit, {{%RuntimeError{message: "oops"}, _}, _} -> :ok
  end

  def genserver_crash(:exit) do
    {:ok, pid} = LoggerHandlerKit.GenServer.start(nil)
    GenServer.call(pid, {:run, fn -> exit("i quit") end})
  catch
    :exit, {"i quit", _} -> :ok
  end

  def genserver_crash(:exit_with_struct) do
    {:ok, pid} = LoggerHandlerKit.GenServer.start(nil)

    GenServer.call(
      pid,
      {:run, fn -> {:stop, %LoggerHandlerKit.FakeStruct{hello: "world"}, :no_state} end}
    )
  catch
    :exit, {%LoggerHandlerKit.FakeStruct{hello: "world"}, _} -> :ok
  end

  def genserver_crash(:throw) do
    {:ok, pid} = LoggerHandlerKit.GenServer.start(nil)
    GenServer.call(pid, {:run, fn -> throw("catch!") end})
  catch
    :exit, {{:bad_return_value, "catch!"}, _} -> :ok
  end

  def genserver_crash(:local_name) do
    {:ok, pid} = LoggerHandlerKit.GenServer.start(nil, name: :"genserver local name")
    GenServer.call(pid, {:run, fn -> raise "oops" end})
  catch
    :exit, {{%RuntimeError{message: "oops"}, _}, _} -> :ok
  end

  def genserver_crash(:global_name) do
    {:ok, pid} = LoggerHandlerKit.GenServer.start(nil, name: {:global, "genserver global name"})
    GenServer.call(pid, {:run, fn -> raise "oops" end})
  catch
    :exit, {{%RuntimeError{message: "oops"}, _}, _} -> :ok
  end

  if System.otp_release() < "27" do
    def genserver_crash(:process_label),
      do:
        raise("""
        Process labels were introduced in OTP 27.
        If you want to run test suite for older Elixir version, considder skipping the test with `@tag skip: System.otp_release() < "27"`
        """)
  else
    def genserver_crash(:process_label) do
      {:ok, pid} = LoggerHandlerKit.GenServer.start(nil)

      GenServer.call(
        pid,
        {:run,
         fn ->
           Process.set_label({:any, "term"})
           raise "oops"
         end}
      )
    catch
      :exit, {{%RuntimeError{message: "oops"}, _}, _} -> :ok
    end
  end

  def genserver_crash(:named_client) do
    Process.register(self(), :named_client)
    {:ok, pid} = LoggerHandlerKit.GenServer.start(nil)
    GenServer.call(pid, {:run, fn -> raise "oops" end})
  catch
    :exit, {{%RuntimeError{message: "oops"}, _}, _} -> :ok
  end

  def genserver_crash(:dead_client) do
    {:ok, pid} = LoggerHandlerKit.GenServer.start(nil)

    mon = Process.monitor(pid)

    # We spawn a process that will call the GenServer with a timeout of 0 and
    # immediately crash. The GenServer will monitor the caller and once it
    # crashes, it will crash itself in return. As a result, at the moment of
    # GenServer crash, the caller is already dead.
    spawn_link(fn ->
      try do
        GenServer.call(
          pid,
          {:run,
           fn {caller, _}, _ ->
             caller_monitor = Process.monitor(caller)
             assert_receive({:DOWN, ^caller_monitor, _, _, _})
             raise "oops"
           end},
          0
        )
      catch
        :exit, {:timeout, {GenServer, :call, _}} -> :ok
      end
    end)

    assert_receive({:DOWN, ^mon, _, _, _})
    :ok
  end

  def genserver_crash(:no_client) do
    {:ok, pid} = LoggerHandlerKit.GenServer.start(nil)
    mon = Process.monitor(pid)
    GenServer.cast(pid, fn -> raise "oops" end)
    assert_receive({:DOWN, ^mon, _, _, _})
    :ok
  end

  @doc """
  `Task`s are a popular way to run asynchronous workloads in Elixir applications.

  Tasks are special in that they break some rules. First of all, technically Task
  errors are reports and include a special `report_cb` callback as per the [Erlang 
  convention](https://www.erlang.org/doc/apps/kernel/logger.html#t:report_cb/0).
  However, usually this callback is not offered a chance to shine as Task errors
  are translated by `Logger.Translator`. This means that Elixir defines 2 ways of 
  formatting `Task` reports: in the `Task` module itself, and in the 
  `Logger.Translator`. In the majority of cases we see the output of the latter. 
  This is not particularly important for handlers, but it's a fun fact nevertheless.

  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "task error exception", %{handler_ref: ref} do
    LoggerHandlerKit.Act.task_error(:exception)
    LoggerHandlerKit.Assert.assert_logged(ref)

    # handler-specific assertions
  end
  ```

  ### Example Log Event (< 1.19)

  ```elixir
  %{
    meta: %{
      error_logger: %{tag: :error_msg},
      pid: #PID<0.321.0>,
      time: 1744770005614313,
      gl: #PID<0.69.0>,
      domain: [:otp, :elixir],
      report_cb: &Task.Supervised.format_report/1,
      callers: [#PID<0.312.0>],
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Act, :"-task_error/1-fun-0-", 0,
          [
            file: ~c"lib/logger_handler_kit/act.ex",
            line: 671,
            error_info: %{module: Exception}
          ]},
         {Task.Supervised, :invoke_mfa, 2,
          [file: ~c"lib/task/supervised.ex", line: 101]}
       ]}
    },
    msg: {:string,
     [
       "Task #PID<0.321.0> started from #PID<0.312.0> terminating",
       [
         [10 | "** (RuntimeError) oops"],
         ["\n    " |
          "(logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:671: anonymous fn/0 in LoggerHandlerKit.Act.task_error/1"],
         ["\n    " |
          "(elixir 1.18.3) lib/task/supervised.ex:101: Task.Supervised.invoke_mfa/2"]
       ],
       "\nFunction: #Function<9.52854244/0 in LoggerHandlerKit.Act.task_error/1>",
       "\n    Args: []"
     ]},
    level: :error
  }
  ```

  ### Example Log Event (1.19+)

  ```elixir
  %{
    meta: %{
      error_logger: %{tag: :error_msg},
      pid: #PID<0.202.0>,
      time: 1744769872184986,
      gl: #PID<0.69.0>,
      domain: [:otp, :elixir],
      report_cb: &Logger.Utils.translated_cb/1,
      callers: [#PID<0.191.0>],
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Act, :"-task_error/1-fun-0-", 0,
          [
            file: ~c"lib/logger_handler_kit/act.ex",
            line: 621,
            error_info: %{module: Exception}
          ]},
         {Task.Supervised, :invoke_mfa, 2,
          [file: ~c"lib/task/supervised.ex", line: 105]}
       ]}
    },
    msg: {:report,
     %{
       label: {Task.Supervisor, :terminating},
       report: %{
         args: [],
         function: #Function<9.61584632/0 in LoggerHandlerKit.Act.task_error/1>,
         name: #PID<0.202.0>,
         reason: {%RuntimeError{message: "oops"},
          [
            {LoggerHandlerKit.Act, :"-task_error/1-fun-0-", 0,
             [
               file: ~c"lib/logger_handler_kit/act.ex",
               line: 621,
               error_info: %{module: Exception}
             ]},
            {Task.Supervised, :invoke_mfa, 2,
             [file: ~c"lib/task/supervised.ex", line: 105]}
          ]},
         process_label: :undefined,
         starter: #PID<0.191.0>
       },
       elixir_translation: [ ... ]
     }},
    level: :error
  }
  ```

  <!-- tabs-close -->
  """
  @doc group: "OTP"
  @spec task_error(:exception | :exit | :throw | :undefined) :: :ok
  def task_error(:exception) do
    {:ok, pid} = Task.start(fn -> raise "oops" end)
    ref = Process.monitor(pid)
    assert_receive({:DOWN, ^ref, _, _, _})
    :ok
  end

  def task_error(:exit) do
    {:ok, pid} = Task.start(fn -> exit("i quit") end)
    ref = Process.monitor(pid)
    assert_receive({:DOWN, ^ref, _, _, _})
    :ok
  end

  def task_error(:throw) do
    {:ok, pid} = Task.start(fn -> throw("catch!") end)
    ref = Process.monitor(pid)
    assert_receive({:DOWN, ^ref, _, _, _})
    :ok
  end

  def task_error(:undefined) do
    {:ok, pid} = Task.start(:module_does_not_exist, :undef, [])
    ref = Process.monitor(pid)
    assert_receive({:DOWN, ^ref, _, _, _})
    :ok
  end

  @doc """
  `:gen_statem` crashes are similar to `GenServer`

  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "gen_statem crash exception", %{handler_ref: ref} do
    LoggerHandlerKit.Act.gen_statem_crash()
    LoggerHandlerKit.Assert.assert_logged(ref)

    # handler-specific assertions
  end
  ```

  ### Example Log Event (< 1.19)

  ```elixir
  %{
    meta: %{
      error_logger: %{tag: :error, report_cb: &:gen_statem.format_log/1},
      line: 4975,
      pid: #PID<0.321.0>,
      time: 1745097781898702,
      file: ~c"gen_statem.erl",
      gl: #PID<0.69.0>,
      domain: [:otp],
      report_cb: &:gen_statem.format_log/2,
      mfa: {:gen_statem, :error_info, 7},
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Act, :"-gen_statem_crash/0-fun-0-", 0,
          [
            file: ~c"lib/logger_handler_kit/act.ex",
            line: 875,
            error_info: %{module: Exception}
          ]},
         {:gen_statem, :loop_state_callback, 11,
          [file: ~c"gen_statem.erl", line: 3735]},
         {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 329]}
       ]}
    },
    msg: {:string,
     [
       [
         ":gen_statem ",
         "#PID<0.321.0>",
         " terminating",
         [
           [10 | "** (RuntimeError) oops"],
           ["\n    " |
            "(logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:875: anonymous fn/0 in LoggerHandlerKit.Act.gen_statem_crash/0"],
           ["\n    " |
            "(stdlib 6.2.1) gen_statem.erl:3735: :gen_statem.loop_state_callback/11"],
           ["\n    " |
            "(stdlib 6.2.1) proc_lib.erl:329: :proc_lib.init_p_do_apply/3"]
         ],
         [],
         "\nQueue: [{{:call, {#PID<0.312.0>, #Reference<0.4279064375.3240624134.253706>}}, {:run, #Function<0.101033180/0 in LoggerHandlerKit.Act.gen_statem_crash/0>}}]",
         "\nPostponed: []"
       ],
       "\nState: ",
       "{:started, nil}",
       "\nCallback mode: ",
       ":state_functions, state_enter: false",
       "\nClient ",
       "#PID<0.312.0>",
       " is alive\n",
       ["\n    " | "(stdlib 6.2.1) gen.erl:241: :gen.do_call/4"],
       ["\n    " | "(stdlib 6.2.1) gen_statem.erl:3250: :gen_statem.call/3"],
       ["\n    " |
        "(logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:871: LoggerHandlerKit.Act.gen_statem_crash/0"],
       ["\n    " |
        "test/default_logger_test.exs:243: LoggerHandlerKit.DefaultLoggerTest.\"test Advanced gen_statem crash exception\"/1"],
       ["\n    " |
        "(ex_unit 1.18.3) lib/ex_unit/runner.ex:511: ExUnit.Runner.exec_test/2"],
       ["\n    " |
        "(ex_unit 1.18.3) lib/ex_unit/capture_log.ex:113: ExUnit.CaptureLog.with_log/2"],
       ["\n    " |
        "(ex_unit 1.18.3) lib/ex_unit/runner.ex:460: anonymous fn/3 in ExUnit.Runner.maybe_capture_log/3"],
       ["\n    " | "(stdlib 6.2.1) timer.erl:595: :timer.tc/2"],
       ["\n    " |
        "(ex_unit 1.18.3) lib/ex_unit/runner.ex:433: anonymous fn/6 in ExUnit.Runner.spawn_test_monitor/4"]
     ]},
    level: :error
  }
  ```

  ### Example Log Event (1.19+)

  ```elixir
  %{
    meta: %{
      error_logger: %{tag: :error, report_cb: &:gen_statem.format_log/1},
      line: 4975,
      pid: #PID<0.222.0>,
      time: 1745097734784539,
      file: ~c"gen_statem.erl",
      gl: #PID<0.69.0>,
      domain: [:otp],
      report_cb: &Logger.Utils.translated_cb/1,
      mfa: {:gen_statem, :error_info, 7},
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Act, :"-gen_statem_crash/0-fun-0-", 0,
          [
            file: ~c"lib/logger_handler_kit/act.ex",
            line: 843,
            error_info: %{module: Exception}
          ]},
         {:gen_statem, :loop_state_callback, 11,
          [file: ~c"gen_statem.erl", line: 3735]},
         {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 329]}
       ]}
    },
    msg: {:report,
     %{
       label: {:gen_statem, :terminate},
       name: #PID<0.222.0>,
       reason: {:error, %RuntimeError{message: "oops"},
        [
          {LoggerHandlerKit.Act, :"-gen_statem_crash/0-fun-0-", 0,
           [
             file: ~c"lib/logger_handler_kit/act.ex",
             line: 843,
             error_info: %{module: Exception}
           ]},
          {:gen_statem, :loop_state_callback, 11,
           [file: ~c"gen_statem.erl", line: 3735]},
          {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 329]}
        ]},
       log: [],
       state: {:started, nil},
       queue: [
         {{:call, {#PID<0.211.0>, #Reference<0.1625241344.3509321731.89483>}},
          {:run,
           #Function<0.101033180/0 in LoggerHandlerKit.Act.gen_statem_crash/0>}}
       ],
       modules: [LoggerHandlerKit.GenStatem],
       process_label: :undefined,
       client_info: {#PID<0.211.0>,
        {#PID<0.211.0>,
         [
           {:gen, :do_call, 4, [file: ~c"gen.erl", line: 241]},
           {:gen_statem, :call, 3, [file: ~c"gen_statem.erl", line: 3250]},
           {LoggerHandlerKit.Act, :gen_statem_crash, 0,
            [file: ~c"lib/logger_handler_kit/act.ex", line: 839]},
           {LoggerHandlerKit.DefaultLoggerTest,
            :"test Advanced gen_statem crash exception", 1,
            [file: ~c"test/default_logger_test.exs", line: 243]},
           {ExUnit.Runner, :exec_test, 2,
            [file: ~c"lib/ex_unit/runner.ex", line: 515]},
           {ExUnit.CaptureLog, :with_log, 2,
            [file: ~c"lib/ex_unit/capture_log.ex", line: 117]},
           {ExUnit.Runner, :"-maybe_capture_log/3-fun-0-", 3,
            [file: ~c"lib/ex_unit/runner.ex", line: 464]},
           {:timer, :tc, 2, [file: ~c"timer.erl", line: 595]},
           {ExUnit.Runner, :"-spawn_test_monitor/4-fun-1-", 6,
            [file: ~c"lib/ex_unit/runner.ex", line: 437]}
         ]}},
       callback_mode: :state_functions,
       postponed: [],
       timeouts: {0, []},
       state_enter: false,
       elixir_translation: [...]
       ]
     }},
    level: :error
  }
  ```

  <!-- tabs-close -->
  """
  @doc group: "OTP"
  @spec gen_statem_crash(:exception | :exit | :throw) :: :ok
  def gen_statem_crash(flavor \\ :exception)

  def gen_statem_crash(:exception) do
    {:ok, pid} = LoggerHandlerKit.GenStatem.start(nil)
    :gen_statem.call(pid, {:run, fn -> raise "oops" end})
  catch
    :exit, {{%RuntimeError{}, _}, _} -> :ok
  end

  def gen_statem_crash(:exit) do
    {:ok, pid} = LoggerHandlerKit.GenStatem.start(nil)
    :gen_statem.call(pid, {:run, fn -> exit("i quit") end})
  catch
    :exit, {"i quit", _} -> :ok
  end

  def gen_statem_crash(:throw) do
    {:ok, pid} = LoggerHandlerKit.GenStatem.start(nil)
    :gen_statem.call(pid, {:run, fn -> throw("catch!") end})
  catch
    :exit, {{{:bad_return_from_state_function, "catch!"}, _}, _} -> :ok
  end

  @doc """
  Bare process crashes are reported as simple string errors, not reports. Another fun
  fact is that an exit, even for a weird reason, is not an error and is not logged.
    
  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "bare process crash exception", %{handler_id: handler_id, handler_ref: ref} do
    LoggerHandlerKit.Act.bare_process_crash(handler_id, :exception)
    LoggerHandlerKit.Assert.assert_logged(ref)

    # handler-specific assertions
  end
  ```

  ### Example Log Event

  ```elixir
  %{
    meta: %{
      error_logger: %{emulator: true, tag: :error},
      pid: #PID<0.214.0>,
      time: 1745101176502155,
      gl: #PID<0.69.0>,
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Act, :"-bare_process_crash/1-fun-0-", 0,
          [
            file: ~c"lib/logger_handler_kit/act.ex",
            line: 1106,
            error_info: %{module: Exception}
          ]}
       ]}
    },
    msg: {:string,
     [
       "Process ",
       "#PID<0.214.0>",
       " raised an exception",
       10,
       "** (RuntimeError) oops",
       ["\n    " |
        "(logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:1106: anonymous fn/0 in LoggerHandlerKit.Act.bare_process_crash/1"]
     ]},
    level: :error
  }
  ```

  <!-- tabs-close -->
  """
  @doc group: "OTP"
  @spec bare_process_crash(handler_id :: :logger.handler_id(), :exception | :throw) :: :ok
  def bare_process_crash(handler_id, flavor \\ :exception)

  def bare_process_crash(handler_id, :exception) do
    {pid, ref} =
      spawn_monitor(fn ->
        receive do
          :go -> :ok
        end

        raise "oops"
      end)

    LoggerHandlerKit.Arrange.allow(self(), pid, handler_id)
    send(pid, :go)
    assert_receive({:DOWN, ^ref, _, _, _})
    :ok
  end

  def bare_process_crash(handler_id, :throw) do
    {pid, ref} =
      spawn_monitor(fn ->
        receive do
          :go -> :ok
        end

        throw("catch!")
      end)

    LoggerHandlerKit.Arrange.allow(self(), pid, handler_id)
    send(pid, :go)
    assert_receive({:DOWN, ^ref, _, _, _})
    :ok
  end

  @doc """
    If `c:GenServer.init/1` callback fails, the caller receives an error tuple. Seemingly, nothing 
    exceptional happened... but SASL knows. And will report.

  ```elixir
  defmodule MyGenserver do
    use GenServer

    def init(_), do: raise "oops"
  end

  {:error, {%RuntimeError{}, _}} = GenServer.start(MyGenserver, nil)

  # This log is only sent if handle_sasl_reports is set to true
  # 21:54:45.734 [error] Process #PID<0.115.0> terminating
  # ** (RuntimeError) oops
  #     iex:4: MyGenserver.init/1
  #     (stdlib 6.2.1) gen_server.erl:2229: :gen_server.init_it/2
  #     (stdlib 6.2.1) gen_server.erl:2184: :gen_server.init_it/6
  #     (stdlib 6.2.1) proc_lib.erl:329: :proc_lib.init_p_do_apply/3
  # Initial Call: MyGenserver.init/1
  # Ancestors: [#PID<0.108.0>, #PID<0.98.0>]
  # Message Queue Length: 0
  # Messages: []
  # Links: []
  # Dictionary: []
  # Trapping Exits: false
  # Status: :running
  # Heap Size: 233
  # Stack Size: 29
  # Reductions: 57
  ```

  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "genserver init crash", %{handler_ref: ref} do
    LoggerHandlerKit.Act.genserver_init_crash()
    LoggerHandlerKit.Assert.assert_logged(ref)

    # handler-specific assertions
  end
  ```

  ### Example Log Event (< 1.19)

  ```elixir
  %{
    meta: %{
      error_logger: %{tag: :error_report, type: :crash_report},
      initial_call: {LoggerHandlerKit.GenServer, :init, 1},
      line: 948,
      pid: #PID<0.214.0>,
      time: 1744844942033945,
      file: ~c"proc_lib.erl",
      gl: #PID<0.69.0>,
      domain: [:otp, :sasl],
      logger_formatter: %{title: ~c"CRASH REPORT"},
      mfa: {:proc_lib, :crash_report, 4},
      report_cb: &:proc_lib.report_cb/2,
      ancestors: [#PID<0.205.0>],
      callers: [#PID<0.205.0>],
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Act, :"-genserver_init_crash/0-fun-0-", 0,
          [
            file: ~c"lib/logger_handler_kit/act.ex",
            line: 840,
            error_info: %{module: Exception}
          ]},
         {:gen_server, :init_it, 2, [file: ~c"gen_server.erl", line: 2229]},
         {:gen_server, :init_it, 6, [file: ~c"gen_server.erl", line: 2184]},
         {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 329]}
       ]}
    },
    msg: {:string,
     [
       "Process ",
       "#PID<0.214.0>",
       " terminating",
       [
         10,
         "** (RuntimeError) oops",
         ["\n    " |
          "(logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:840: anonymous fn/0 in LoggerHandlerKit.Act.genserver_init_crash/0"],
         ["\n    " | "(stdlib 6.2.1) gen_server.erl:2229: :gen_server.init_it/2"],
         ["\n    " | "(stdlib 6.2.1) gen_server.erl:2184: :gen_server.init_it/6"],
         ["\n    " |
          "(stdlib 6.2.1) proc_lib.erl:329: :proc_lib.init_p_do_apply/3"]
       ],
       [
         ~c"\n",
         "Initial Call: ",
         "LoggerHandlerKit.GenServer.init/1",
         ~c"\n",
         "Ancestors: ",
         "[#PID<0.205.0>]",
         [~c"\n", "Message Queue Length", 58, 32, "0"],
         [~c"\n", "Messages", 58, 32, "[]"],
         [~c"\n", "Links", 58, 32, "[]"],
         [~c"\n", "Dictionary", 58, 32, "[\"$callers\": [#PID<0.205.0>]]"],
         [~c"\n", "Trapping Exits", 58, 32, "false"],
         [~c"\n", "Status", 58, 32, ":running"],
         [~c"\n", "Heap Size", 58, 32, "233"],
         [~c"\n", "Stack Size", 58, 32, "29"],
         [~c"\n", "Reductions", 58, 32, "72"]
       ],
       []
     ]},
    level: :error
  }
  ```

  ### Example Log Event (1.19+)

  ```elixir
  %{
    meta: %{
      error_logger: %{tag: :error_report, type: :crash_report},
      initial_call: {LoggerHandlerKit.GenServer, :init, 1},
      line: 948,
      pid: #PID<0.326.0>,
      time: 1744844985798744,
      file: ~c"proc_lib.erl",
      gl: #PID<0.69.0>,
      domain: [:otp, :sasl],
      logger_formatter: %{title: ~c"CRASH REPORT"},
      mfa: {:proc_lib, :crash_report, 4},
      report_cb: &Logger.Utils.translated_cb/1,
      ancestors: [#PID<0.315.0>],
      callers: [#PID<0.315.0>],
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Act, :"-genserver_init_crash/0-fun-0-", 0,
          [
            file: ~c"lib/logger_handler_kit/act.ex",
            line: 868,
            error_info: %{module: Exception}
          ]},
         {:gen_server, :init_it, 2, [file: ~c"gen_server.erl", line: 2229]},
         {:gen_server, :init_it, 6, [file: ~c"gen_server.erl", line: 2184]},
         {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 329]}
       ]}
    },
    msg: {:report,
     %{
       label: {:proc_lib, :crash},
       report: [
         [
           initial_call: {LoggerHandlerKit.GenServer, :init, [:Argument__1]},
           pid: #PID<0.326.0>,
           registered_name: [],
           process_label: :undefined,
           error_info: {:error, %RuntimeError{message: "oops"},
            [
              {LoggerHandlerKit.Act, :"-genserver_init_crash/0-fun-0-", 0,
               [
                 file: ~c"lib/logger_handler_kit/act.ex",
                 line: 868,
                 error_info: %{module: Exception}
               ]},
              {:gen_server, :init_it, 2, [file: ~c"gen_server.erl", line: 2229]},
              {:gen_server, :init_it, 6, [file: ~c"gen_server.erl", line: 2184]},
              {:proc_lib, :init_p_do_apply, 3,
               [file: ~c"proc_lib.erl", line: 329]}
            ]},
           ancestors: [#PID<0.315.0>],
           message_queue_len: 0,
           messages: [],
           links: [],
           dictionary: ["$callers": [#PID<0.315.0>]],
           trap_exit: false,
           status: :running,
           heap_size: 233,
           stack_size: 29,
           reductions: 72
         ],
         []
       ],
       elixir_translation: [...]
     }},
    level: :error
  }
  ```

  <!-- tabs-close -->
  """
  @doc group: "SASL"
  def genserver_init_crash() do
    {:error, {%RuntimeError{message: "oops"}, _}} =
      LoggerHandlerKit.GenServer.start({:run, fn -> raise "oops" end})
  end

  @doc """
  Unlike bare process crashes, `:proc_lib` crashes are reported as reports and with plenty of metadata.

  `:proc_lib` is an Erlang module used for working with processes [_that adhere to
  OTP design principles_](https://www.erlang.org/doc/apps/stdlib/proc_lib.html).

  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test ":proc_lib crash exception", %{handler_ref: ref} do
    LoggerHandlerKit.Act.proc_lib_crash(:exception)
    LoggerHandlerKit.Assert.assert_logged(ref)

    # handler-specific assertions
  end
  ```

  ### Example Log Event (< 1.19)

  ```elixir
  %{
    meta: %{
      error_logger: %{tag: :error_report, type: :crash_report},
      initial_call: {LoggerHandlerKit.Act, :"-proc_lib_crash/0-fun-0-", 0},
      line: 948,
      pid: #PID<0.321.0>,
      time: 1745103540970106,
      file: ~c"proc_lib.erl",
      gl: #PID<0.69.0>,
      domain: [:otp, :sasl],
      logger_formatter: %{title: ~c"CRASH REPORT"},
      mfa: {:proc_lib, :crash_report, 4},
      report_cb: &:proc_lib.report_cb/2,
      ancestors: [#PID<0.312.0>],
      callers: [#PID<0.312.0>],
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Act, :"-proc_lib_crash/0-fun-0-", 1,
          [
            file: ~c"lib/logger_handler_kit/act.ex",
            line: 1350,
            error_info: %{module: Exception}
          ]},
         {:proc_lib, :init_p, 3, [file: ~c"proc_lib.erl", line: 313]}
       ]}
    },
    msg: {:string,
     [
       "Process ",
       "#PID<0.321.0>",
       " terminating",
       [
         10,
         "** (RuntimeError) oops",
         ["\n    " |
          "(logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:1350: anonymous fn/1 in LoggerHandlerKit.Act.proc_lib_crash/0"],
         ["\n    " | "(stdlib 6.2.1) proc_lib.erl:313: :proc_lib.init_p/3"]
       ],
       [
         ~c"\n",
         "Initial Call: ",
         "anonymous fn/0 in LoggerHandlerKit.Act.proc_lib_crash/0",
         ~c"\n",
         "Ancestors: ",
         "[#PID<0.312.0>]",
         [~c"\n", "Message Queue Length", 58, 32, "0"],
         [~c"\n", "Messages", 58, 32, "[]"],
         [~c"\n", "Links", 58, 32, "[]"],
         [~c"\n", "Dictionary", 58, 32, "[\"$callers\": [#PID<0.312.0>]]"],
         [~c"\n", "Trapping Exits", 58, 32, "false"],
         [~c"\n", "Status", 58, 32, ":running"],
         [~c"\n", "Heap Size", 58, 32, "376"],
         [~c"\n", "Stack Size", 58, 32, "29"],
         [~c"\n", "Reductions", 58, 32, "423"]
       ],
       []
     ]},
    level: :error
  }
  ```

  ### Example Log Event (1.19+)

  ```elixir
  %{
    meta: %{
      error_logger: %{tag: :error_report, type: :crash_report},
      initial_call: {LoggerHandlerKit.Act, :"-proc_lib_crash/0-fun-0-", 0},
      line: 948,
      pid: #PID<0.215.0>,
      time: 1745103479744344,
      file: ~c"proc_lib.erl",
      gl: #PID<0.69.0>,
      domain: [:otp, :sasl],
      logger_formatter: %{title: ~c"CRASH REPORT"},
      mfa: {:proc_lib, :crash_report, 4},
      report_cb: &Logger.Utils.translated_cb/1,
      ancestors: [#PID<0.204.0>],
      callers: [#PID<0.204.0>],
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Act, :"-proc_lib_crash/0-fun-0-", 1,
          [
            file: ~c"lib/logger_handler_kit/act.ex",
            line: 1355,
            error_info: %{module: Exception}
          ]},
         {:proc_lib, :init_p, 3, [file: ~c"proc_lib.erl", line: 313]}
       ]}
    },
    msg: {:report,
     %{
       label: {:proc_lib, :crash},
       report: [
         [
           initial_call: {LoggerHandlerKit.Act, :"-proc_lib_crash/0-fun-0-", []},
           pid: #PID<0.215.0>,
           registered_name: [],
           process_label: :undefined,
           error_info: {:error, %RuntimeError{message: "oops"},
            [
              {LoggerHandlerKit.Act, :"-proc_lib_crash/0-fun-0-", 1,
               [
                 file: ~c"lib/logger_handler_kit/act.ex",
                 line: 1355,
                 error_info: %{module: Exception}
               ]},
              {:proc_lib, :init_p, 3, [file: ~c"proc_lib.erl", line: 313]}
            ]},
           ancestors: [#PID<0.204.0>],
           message_queue_len: 0,
           messages: [],
           links: [],
           dictionary: ["$callers": [#PID<0.204.0>]],
           trap_exit: false,
           status: :running,
           heap_size: 376,
           stack_size: 29,
           reductions: 429
         ],
         []
       ],
       elixir_translation: [...]
     }},
    level: :error
  }
  ```

  <!-- tabs-close -->
  """
  @doc group: "SASL"
  @spec proc_lib_crash(:exception | :exit | :throw) :: :ok
  def proc_lib_crash(flavor \\ :exception)

  def proc_lib_crash(:exception) do
    callers = [self() | Process.get(:"$callers") || []]

    pid =
      :proc_lib.spawn(fn ->
        Process.put(:"$callers", callers)
        raise "oops"
      end)

    ref = Process.monitor(pid)

    assert_receive({:DOWN, ^ref, _, _, _})
    :ok
  end

  def proc_lib_crash(:exit) do
    callers = [self() | Process.get(:"$callers") || []]

    pid =
      :proc_lib.spawn(fn ->
        Process.put(:"$callers", callers)
        exit("i quit")
      end)

    ref = Process.monitor(pid)

    assert_receive({:DOWN, ^ref, _, _, _})
    :ok
  end

  def proc_lib_crash(:throw) do
    callers = [self() | Process.get(:"$callers") || []]

    pid =
      :proc_lib.spawn(fn ->
        Process.put(:"$callers", callers)
        throw("catch!")
      end)

    ref = Process.monitor(pid)

    assert_receive({:DOWN, ^ref, _, _, _})
    :ok
  end

  @doc """
  `Supervisor` module emits quite a few log reports, which are gated behind the 
  `handle_sasl_reports` configuration option. They come in different log levels as 
  well!

  <!-- tabs-open -->

  ### Example Test

  ```elixir
  test "supervisor progress report failed to start child", %{handler_ref: ref, io_ref: io_ref} do
    LoggerHandlerKit.Act.supervisor_progress_report(:failed_to_start_child)
    LoggerHandlerKit.Assert.assert_logged(ref)

    # handler-specific assertions
  end
  ```

  ### Example Log Event (< 1.19)

  ```elixir
  %{
    meta: %{
      error_logger: %{
        tag: :error_report,
        type: :supervisor_report,
        report_cb: &:supervisor.format_log/1
      },
      line: 937,
      pid: #PID<0.200.0>,
      time: 1745204329480468,
      file: ~c"supervisor.erl",
      gl: #PID<0.69.0>,
      domain: [:otp, :sasl],
      logger_formatter: %{title: ~c"SUPERVISOR REPORT"},
      mfa: {:supervisor, :start_children, 2},
      report_cb: &:supervisor.format_log/2
    },
    msg: {:string,
     [
       "Child ",
       ":task",
       " of Supervisor ",
       ["#PID<0.200.0>", " (", "Supervisor.Default", 41],
       32,
       "failed to start",
       "\n** (exit) ",
       ":reason",
       "\nStart Call: ",
       "LoggerHandlerKit.Helper.run(#Function<26.21775298/0 in LoggerHandlerKit.Act.supervisor_progress_report/1>)",
       ["\nRestart: " | ":permanent"],
       [],
       ["\nShutdown: " | "5000"],
       ["\nType: " | ":worker"]
     ]},
    level: :error
  }
  ```

  ### Example Log Event (1.19+)

  ```elixir
  %{
    meta: %{
      error_logger: %{
        tag: :error_report,
        type: :supervisor_report,
        report_cb: &:supervisor.format_log/1
      },
      line: 937,
      pid: #PID<0.326.0>,
      time: 1745204485120228,
      file: ~c"supervisor.erl",
      gl: #PID<0.69.0>,
      domain: [:otp, :sasl],
      logger_formatter: %{title: ~c"SUPERVISOR REPORT"},
      mfa: {:supervisor, :start_children, 2},
      report_cb: &Logger.Utils.translated_cb/1
    },
    msg: {:report,
     %{
       label: {:supervisor, :start_error},
       report: [
         supervisor: {#PID<0.326.0>, Supervisor.Default},
         errorContext: :start_error,
         reason: :reason,
         offender: [
           pid: :undefined,
           id: :task,
           mfargs: {LoggerHandlerKit.Helper, :run,
            [#Function<26.30156712/0 in LoggerHandlerKit.Act.supervisor_progress_report/1>]},
           restart_type: :permanent,
           significant: false,
           shutdown: 5000,
           child_type: :worker
         ]
       ],
       elixir_translation: [...]
     }},
    level: :error
  }
  ```

  <!-- tabs-close -->
  """
  @doc group: "SASL"
  @spec supervisor_progress_report(:failed_to_start_child | :child_started | :child_terminated) ::
          :ok
  def supervisor_progress_report(flavor \\ :failed_to_start_child)

  def supervisor_progress_report(:child_started) do
    {:ok, pid} = Supervisor.start_link([], strategy: :one_for_one)
    callers = [self() | Process.get(:"$callers") || []]

    ref = Process.monitor(pid)

    Supervisor.start_child(pid, %{
      id: :task,
      start:
        {LoggerHandlerKit.Helper, :run,
         [
           fn ->
             Process.put(:"$callers", callers)
             Agent.start_link(fn -> nil end)
           end
         ]}
    })

    Process.exit(pid, :normal)
    assert_receive({:DOWN, ^ref, _, _, _})
    :ok
  end

  def supervisor_progress_report(:failed_to_start_child) do
    Process.flag(:trap_exit, true)
    callers = [self() | Process.get(:"$callers") || []]

    children = [
      %{
        id: :task,
        start:
          {LoggerHandlerKit.Helper, :run,
           [
             fn ->
               Process.put(:"$callers", callers)
               {:error, :reason}
             end
           ]}
      }
    ]

    {:error, {:shutdown, {:failed_to_start_child, :task, :reason}}} =
      Supervisor.start_link(children, strategy: :one_for_one)

    :ok
  end

  def supervisor_progress_report(:child_terminated) do
    Process.flag(:trap_exit, true)
    callers = [self() | Process.get(:"$callers") || []]
    {:ok, child_pid} = LoggerHandlerKit.GenServer.start(nil)

    children = [
      %{
        id: :task,
        start:
          {LoggerHandlerKit.Helper, :run,
           [
             fn ->
               Process.put(:"$callers", callers)
               Process.link(child_pid)
               {:ok, child_pid}
             end
           ]}
      }
    ]

    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one, max_restarts: 0)

    GenServer.cast(child_pid, {:run,
     fn ->
       # This GenServer crash will also be reported, but it's not the focus of
       # the test. By removing the callers, we'll make the ownership filter
       # filter this report out.
       Process.put(:"$callers", [])
       exit(:stop)
     end})

    assert_receive({:EXIT, ^pid, _})
    :ok
  end

  @doc """
  Sets the `extra` key in Logger metadata to a sample value of some interesting type.

  Metadata can contain arbitrary Elixir terms, and the primary challenge that
  loggers face when exporting it is serialization. There is no universally good
  way to represent an Elixir term as text, so handlers or formatters must make
  hard choices. Some examples:

  * Binary strings can contain non-printable characters.
  * Structs by default don't implement the `String.Chars` protocol. When they do, the implementation might be designed for a different purpose than logging.
  * Tuples can be inspected as text but lose their structure (in JSON), or serialized as lists which preserves structure but misleads about the original type.
  * Charlists are indistinguishable from lists in JSON serialization.

  The default text formatter [skips](`Logger.Formatter#module-metadata`) many of these complex cases.
  """
  @doc group: "Metadata"
  @dialyzer :no_improper_lists
  @metadata_types %{
    boolean: true,
    string: "hello world",
    binary: <<1, 2, 3>>,
    atom: :foo,
    integer: 42,
    datetime: ~U[2025-06-01T12:34:56.000Z],
    struct: %LoggerHandlerKit.FakeStruct{hello: "world"},
    tuple: {:ok, "hello"},
    keyword: [hello: "world"],
    improper_keyword: [{:a, 1} | {:b, 2}],
    fake_keyword: [{:a, 1}, {:b, 2, :c}],
    list: [1, 2, 3],
    improper_list: [1, 2 | 3],
    map: %{:hello => "world", "foo" => "bar"},
    function: &__MODULE__.metadata_serialization/1
  }
  @spec metadata_serialization(
          :boolean
          | :string
          | :binary
          | :atom
          | :integer
          | :datetime
          | :struct
          | :tuple
          | :keyword
          | :improper_keyword
          | :fake_keyword
          | :list
          | :improper_list
          | :map
          | :function
          | :anonymous_function
          | :pid
          | :ref
          | :port
        ) :: :ok
  def metadata_serialization(:pid), do: Logger.metadata(extra: self())

  def metadata_serialization(:anonymous_function),
    do: Logger.metadata(extra: fn -> "hello world" end)

  def metadata_serialization(:ref), do: Logger.metadata(extra: make_ref())
  def metadata_serialization(:port), do: Logger.metadata(extra: Port.list() |> hd())

  def metadata_serialization(:all) do
    all =
      Map.merge(@metadata_types, %{
        pid: self(),
        anonymous_function: fn -> "hello world" end,
        ref: make_ref(),
        port: Port.list() |> hd()
      })

    Logger.metadata(extra: all)
  end

  def metadata_serialization(case), do: Logger.metadata(extra: Map.fetch!(@metadata_types, case))

  @doc """
  Starts a web server powered by Cowboy or Bandit and sends a request that triggers an error during the Plug pipeline.

  See [Plug integration guide](guides/plug-integration.md) for more details.

  <!-- tabs-open -->

  ### Example Test

  ```elixir
  # You only need to create your own router if you want to test custom plugs that somehow affect logging
  defmodule MyPlug do
    use Plug.Router
    
    plug MyCustomPlug
    plug :match
    plug :dispatch
    
    forward "/", to: LoggerHandlerKit.Plug
  end

  test "Bandit: plug exception", %{handler_ref: ref, io_ref: io_ref} do
    LoggerHandlerKit.Act.plug_error(:exception, Bandit, MyPlug)
    LoggerHandlerKit.Assert.assert_logged(ref)
    
    # handler-specific assertions
  end  
  ```

  ### Example Log Event (Bandit)

  ```elixir
  %{
    meta: %{
      line: 242,
      pid: #PID<0.556.0>,
      time: 1750196815012775,
      file: ~c"lib/bandit/pipeline.ex",
      gl: #PID<0.69.0>,
      domain: [:elixir, :bandit],
      application: :bandit,
      mfa: {Bandit.Pipeline, :handle_error, 7},
      plug: {LoggerHandlerKit.Plug, %{test_pid: #PID<0.240.0>}},
      conn: %Plug.Conn{...},
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Plug, :"-do_match/4-fun-1-", 2,
          [
            file: ~c"lib/logger_handler_kit/plug.ex",
            line: 8,
            error_info: %{module: Exception}
          ]},
         {LoggerHandlerKit.Plug, :"-dispatch/2-fun-0-", 4,
          [file: ~c"deps/plug/lib/plug/router.ex", line: 246]},
         {:telemetry, :span, 3,
          [
            file: ~c"/Users/user/projects/logger_handler_kit/deps/telemetry/src/telemetry.erl",
            line: 324
          ]},
         {LoggerHandlerKit.Plug, :dispatch, 2,
          [file: ~c"deps/plug/lib/plug/router.ex", line: 242]},
         {LoggerHandlerKit.Plug, :plug_builder_call, 2,
          [file: ~c"lib/logger_handler_kit/plug.ex", line: 1]},
         {Bandit.Pipeline, :call_plug!, 2,
          [file: ~c"lib/bandit/pipeline.ex", line: 131]},
         {Bandit.Pipeline, :run, 5, [file: ~c"lib/bandit/pipeline.ex", line: 42]},
         {Bandit.HTTP1.Handler, :handle_data, 3,
          [file: ~c"lib/bandit/http1/handler.ex", line: 13]},
         {Bandit.DelegatingHandler, :handle_data, 3,
          [file: ~c"lib/bandit/delegating_handler.ex", line: 18]},
         {Bandit.DelegatingHandler, :handle_continue, 2,
          [file: ~c"lib/bandit/delegating_handler.ex", line: 8]},
         {:gen_server, :try_handle_continue, 3,
          [file: ~c"gen_server.erl", line: 2335]},
         {:gen_server, :loop, 7, [file: ~c"gen_server.erl", line: 2244]},
         {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 329]}
       ]}
    },
    msg: {:string,
     "** (RuntimeError) oops\n    (logger_handler_kit 0.2.0) lib/logger_handler_kit/plug.ex:8: anonymous fn/2 in LoggerHandlerKit.Plug.do_match/4\n    (logger_handler_kit 0.2.0) deps/plug/lib/plug/router.ex:246: anonymous fn/4 in LoggerHandlerKit.Plug.dispatch/2\n    (telemetry 1.3.0) /Users/user/projects/logger_handler_kit/deps/telemetry/src/telemetry.erl:324: :telemetry.span/3\n    (logger_handler_kit 0.2.0) deps/plug/lib/plug/router.ex:242: LoggerHandlerKit.Plug.dispatch/2\n    (logger_handler_kit 0.2.0) lib/logger_handler_kit/plug.ex:1: LoggerHandlerKit.Plug.plug_builder_call/2\n    (bandit 1.7.0) lib/bandit/pipeline.ex:131: Bandit.Pipeline.call_plug!/2\n    (bandit 1.7.0) lib/bandit/pipeline.ex:42: Bandit.Pipeline.run/5\n    (bandit 1.7.0) lib/bandit/http1/handler.ex:13: Bandit.HTTP1.Handler.handle_data/3\n    (bandit 1.7.0) lib/bandit/delegating_handler.ex:18: Bandit.DelegatingHandler.handle_data/3\n    (bandit 1.7.0) lib/bandit/delegating_handler.ex:8: Bandit.DelegatingHandler.handle_continue/2\n    (stdlib 6.2.2) gen_server.erl:2335: :gen_server.try_handle_continue/3\n    (stdlib 6.2.2) gen_server.erl:2244: :gen_server.loop/7\n    (stdlib 6.2.2) proc_lib.erl:329: :proc_lib.init_p_do_apply/3\n"},
    level: :error
  }
  ```

  ### Example Log Event (Cowboy) (Elixir 1.19+)

  ```elixir
  %{
    meta: %{
      error_logger: %{tag: :error},
      pid: #PID<0.454.0>,
      time: 1750197653870258,
      gl: #PID<0.69.0>,
      domain: [:cowboy],
      report_cb: &Logger.Utils.translated_cb/1,
      conn: %Plug.Conn{...},
      crash_reason: {%RuntimeError{message: "oops"},
       [
         {LoggerHandlerKit.Plug, :"-do_match/4-fun-1-", 2,
          [
            file: ~c"lib/logger_handler_kit/plug.ex",
            line: 8,
            error_info: %{module: Exception}
          ]},
         {LoggerHandlerKit.Plug, :"-dispatch/2-fun-0-", 4,
          [file: ~c"deps/plug/lib/plug/router.ex", line: 246]},
         {:telemetry, :span, 3,
          [
            file: ~c"/Users/user/projects/logger_handler_kit/deps/telemetry/src/telemetry.erl",
            line: 324
          ]},
         {LoggerHandlerKit.Plug, :dispatch, 2,
          [file: ~c"deps/plug/lib/plug/router.ex", line: 242]},
         {LoggerHandlerKit.Plug, :plug_builder_call, 2,
          [file: ~c"lib/logger_handler_kit/plug.ex", line: 1]},
         {Plug.Cowboy.Handler, :init, 2,
          [file: ~c"lib/plug/cowboy/handler.ex", line: 11]},
         {:cowboy_handler, :execute, 2,
          [
            file: ~c"/Users/user/projects/logger_handler_kit/deps/cowboy/src/cowboy_handler.erl",
            line: 37
          ]},
         {:cowboy_stream_h, :execute, 3,
          [
            file: ~c"/Users/user/projects/logger_handler_kit/deps/cowboy/src/cowboy_stream_h.erl",
            line: 310
          ]},
         {:cowboy_stream_h, :request_process, 3,
          [
            file: ~c"/Users/user/projects/logger_handler_kit/deps/cowboy/src/cowboy_stream_h.erl",
            line: 299
          ]},
         {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 329]}
       ]}
    },
    msg: {:report,
     %{
       args: [
         LoggerHandlerKit.Plug.HTTP,
         #PID<0.454.0>,
         1,
         #PID<0.455.0>,
         {{{%RuntimeError{message: "oops"},
            [
              {LoggerHandlerKit.Plug, :"-do_match/4-fun-1-", 2,
               [
                 file: ~c"lib/logger_handler_kit/plug.ex",
                 line: 8,
                 error_info: %{module: Exception}
               ]},
              {LoggerHandlerKit.Plug, :"-dispatch/2-fun-0-", 4,
               [file: ~c"deps/plug/lib/plug/router.ex", line: 246]},
              {:telemetry, :span, 3,
               [
                 file: ~c"/Users/user/projects/logger_handler_kit/deps/telemetry/src/telemetry.erl",
                 line: 324
               ]},
              {LoggerHandlerKit.Plug, :dispatch, 2,
               [file: ~c"deps/plug/lib/plug/router.ex", line: 242]},
              {LoggerHandlerKit.Plug, :plug_builder_call, 2,
               [file: ~c"lib/logger_handler_kit/plug.ex", line: 1]},
              {Plug.Cowboy.Handler, :init, 2,
               [file: ~c"lib/plug/cowboy/handler.ex", line: 11]},
              {:cowboy_handler, :execute, 2,
               [
                 file: ~c"/Users/user/projects/logger_handler_kit/deps/cowboy/src/cowboy_handler.erl",
                 line: 37
               ]},
              {:cowboy_stream_h, :execute, 3,
               [
                 file: ~c"/Users/user/projects/logger_handler_kit/deps/cowboy/src/cowboy_stream_h.erl",
                 line: 310
               ]},
              {:cowboy_stream_h, :request_process, 3,
               [
                 file: ~c"/Users/user/projects/logger_handler_kit/deps/cowboy/src/cowboy_stream_h.erl",
                 line: 299
               ]},
              {:proc_lib, :init_p_do_apply, 3,
               [file: ~c"proc_lib.erl", line: 329]}
            ]},
           {LoggerHandlerKit.Plug, :call,
            [
              %Plug.Conn{},
              %{test_pid: #PID<0.238.0>}
            ]}}, []}
       ],
       label: {:error_logger, :error_msg},
       format: ~c"Ranch listener ~p, connection process ~p, stream ~p had its request process ~p exit with reason ~0p~n",
       elixir_translation: [
         "#PID<0.455.0>",
         " running ",
         "LoggerHandlerKit.Plug",
         [" (connection ", "#PID<0.454.0>", ", stream id ", "1", 41],
         " terminated\n",
         [
           ["Server: ", "localhost", ":", "8001", 32, 40, "http", 41, 10],
           ["Request: ", "GET", 32, "/exception", 10]
         ] |
         "** (exit) an exception was raised:\n    ** (RuntimeError) oops\n        (logger_handler_kit 0.2.0) lib/logger_handler_kit/plug.ex:8: anonymous fn/2 in LoggerHandlerKit.Plug.do_match/4\n        (logger_handler_kit 0.2.0) deps/plug/lib/plug/router.ex:246: anonymous fn/4 in LoggerHandlerKit.Plug.dispatch/2\n        (telemetry 1.3.0) /Users/user/projects/logger_handler_kit/deps/telemetry/src/telemetry.erl:324: :telemetry.span/3\n        (logger_handler_kit 0.2.0) deps/plug/lib/plug/router.ex:242: LoggerHandlerKit.Plug.dispatch/2\n        (logger_handler_kit 0.2.0) lib/logger_handler_kit/plug.ex:1: LoggerHandlerKit.Plug.plug_builder_call/2\n        (plug_cowboy 2.7.3) lib/plug/cowboy/handler.ex:11: Plug.Cowboy.Handler.init/2\n        (cowboy 2.13.0) /Users/user/projects/logger_handler_kit/deps/cowboy/src/cowboy_handler.erl:37: :cowboy_handler.execute/2\n        (cowboy 2.13.0) /Users/user/projects/logger_handler_kit/deps/cowboy/src/cowboy_stream_h.erl:310: :cowboy_stream_h.execute/3\n        (cowboy 2.13.0) /Users/user/projects/logger_handler_kit/deps/cowboy/src/cowboy_stream_h.erl:299: :cowboy_stream_h.request_process/3\n        (stdlib 6.2.2) proc_lib.erl:329: :proc_lib.init_p_do_apply/3"
       ]
     }},
    level: :error
  }
  ```

  <!-- tabs-close -->
  """
  @doc group: "Plug"
  @spec plug_error(:exception | :throw | :exit, Bandit | Plug.Cowboy, module()) :: :ok
  def plug_error(
        flavour \\ :exception,
        web_server \\ Bandit,
        router_plug \\ LoggerHandlerKit.Plug
      ) do
    ExUnit.Callbacks.start_supervised!(
      {web_server, [plug: {router_plug, %{test_pid: self()}}, scheme: :http, port: 8001]}
    )

    {:ok, conn} = Mint.HTTP.connect(:http, "localhost", 8001)
    {:ok, _conn, _request_ref} = Mint.HTTP.request(conn, "GET", "/#{flavour}", [], nil)
    :ok
  end
end
