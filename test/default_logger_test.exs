defmodule LoggerHandlerKit.DefaultLoggerTest do
  use ExUnit.Case, async: true

  setup {LoggerHandlerKit.Arrange, :ensure_per_handler_translation}

  setup do
    ref = make_ref()
    io_device = start_link_supervised!({FakeIODevice, %{test_pid: self(), ref: ref}})
    %{io_device: io_device, io_ref: ref}
  end

  setup %{test: test, io_device: io_device} = context do
    big_config_override = Map.take(context, [:handle_otp_reports, :handle_sasl_reports, :level])

    {context, on_exit} =
      LoggerHandlerKit.Arrange.add_handler(
        test,
        :logger_std_h,
        %{
          type: {:device, io_device}
        },
        Map.merge(%{formatter: Logger.default_formatter(metadata: [:extra])}, big_config_override)
      )

    on_exit(on_exit)
    context
  end

  @moduletag capture_log: true

  describe "Basic" do
    test "string message", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[info] Hello World"
    end

    test "charlist message", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.charlist_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[info] Hello World"
    end

    test "chardata message", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.chardata_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[info] Hello World"
    end

    test "improper chardata message", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.chardata_message(:improper)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[info] Hello World"
    end

    test "keyword report", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.keyword_report()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[info] [hello: \"world\"]"
    end

    test "map report", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.map_report()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[info] [hello: \"world\"]"
    end

    test "struct report", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.struct_report()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[info] [__struct__: LoggerHandlerKit.FakeStruct, hello: \"world\"]"
    end

    test "io format", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.io_format()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[info] Hello World"
    end

    test "log with crash reason: exception", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.log_with_crash_reason(:exception)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Handled Exception"
    end

    test "log with crash reason: throw", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.log_with_crash_reason(:throw)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Caught"
    end

    test "log with crash reason: exit", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.log_with_crash_reason(:exit)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Exited"
    end
  end

  describe "OTP" do
    test "genserver crash exception", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.genserver_crash(:exception)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] GenServer #PID"
      assert msg =~ "terminating"
      assert msg =~ "** (RuntimeError) oops"
    end

    test "genserver crash exit", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.genserver_crash(:exit)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] GenServer #PID"
      assert msg =~ "terminating"
      assert msg =~ "** (stop) \"i quit\""
    end

    test "genserver crash exit with struct", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.genserver_crash(:exit_with_struct)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] GenServer #PID"
      assert msg =~ "terminating"
      assert msg =~ "** (stop) %LoggerHandlerKit.FakeStruct{hello: \"world\"}"
    end

    test "genserver crash throw", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.genserver_crash(:throw)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] GenServer #PID"
      assert msg =~ "terminating"
      assert msg =~ "** (stop) bad return value: \"catch!\""
    end

    test "genserver crash with local name", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.genserver_crash(:local_name)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] GenServer :\"genserver local name\""
    end

    test "genserver crash with global name", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.genserver_crash(:global_name)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] GenServer \"genserver global name\""
    end

    @tag skip: System.otp_release() < "27"
    test "genserver crash with process label", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.genserver_crash(:process_label)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "Label: {:any, \"term\"}"
    end

    test "genserver crash with named client", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.genserver_crash(:named_client)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "Client :named_client is alive"
    end

    test "genserver crash with dead client", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.genserver_crash(:dead_client)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "Client #PID"
      assert msg =~ "is dead"
    end

    test "genserver crash with no client", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.genserver_crash(:no_client)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      refute msg =~ "Client"
    end

    test "task error exception", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.task_error(:exception)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Task #PID"
      assert msg =~ " started from #PID"
      assert msg =~ "** (RuntimeError) oops"
    end

    test "task error exit", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.task_error(:exit)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Task #PID"
      assert msg =~ " started from #PID"
      assert msg =~ "(stop) \"i quit\""
    end

    test "task error throw", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.task_error(:throw)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Task #PID"
      assert msg =~ " started from #PID"
      assert msg =~ "(stop) {:nocatch, \"catch!\"}"
    end

    test "task error undefined", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.task_error(:undefined)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Task #PID"
      assert msg =~ " started from #PID"

      assert msg =~
               "(UndefinedFunctionError) function :module_does_not_exist.undef/0 is undefined"
    end

    # Before Elixir 1.17 gen_statem crashes were swallowed by Logger.Translator
    # https://github.com/elixir-lang/elixir/pull/13451
    @tag skip: System.version() < "1.17"
    test "gen_statem crash exception", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.gen_statem_crash(:exception)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] :gen_statem #PID"
      assert msg =~ "** (RuntimeError) oops"
    end

    @tag skip: System.version() < "1.17"
    test "gen_statem crash exit", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.gen_statem_crash(:exit)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] :gen_statem #PID"
      assert msg =~ "** (stop) \"i quit\""
    end

    @tag skip: System.version() < "1.17"
    test "gen_statem crash throw", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.gen_statem_crash(:throw)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] :gen_statem #PID"
      assert msg =~ "** (stop) {:bad_return_from_state_function, \"catch!\"}"
    end

    test "bare process crash exception", %{
      handler_id: handler_id,
      handler_ref: ref,
      io_ref: io_ref
    } do
      LoggerHandlerKit.Act.bare_process_crash(handler_id, :exception)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Process #PID"
      assert msg =~ " raised an exception"
      assert msg =~ "** (RuntimeError) oops"
    end

    test "bare process crash throw", %{handler_id: handler_id, handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.bare_process_crash(handler_id, :throw)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Process #PID"
      assert msg =~ " raised an exception"
      assert msg =~ "** (ErlangError) Erlang error: {:nocatch, \"catch!\"}"
    end
  end

  describe "SASL" do
    @describetag handle_sasl_reports: true

    test "genserver init crash", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.genserver_init_crash()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Process #PID"
      assert msg =~ "terminating"
      assert msg =~ "** (RuntimeError) oops"
    end

    test ":proc_lib crash exception", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.proc_lib_crash(:exception)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Process #PID"
      assert msg =~ "terminating"
      assert msg =~ "** (RuntimeError) oops"
    end

    test ":proc_lib crash exit", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.proc_lib_crash(:exit)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Process #PID"
      assert msg =~ "terminating"
      assert msg =~ "** (exit) \"i quit\""
    end

    test ":proc_lib crash throw", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.proc_lib_crash(:throw)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Process #PID"
      assert msg =~ "terminating"
      assert msg =~ "** (throw) \"catch!\""
    end

    @tag level: :debug
    test "supervisor progress report child started", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.supervisor_progress_report(:child_started)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}

      if System.otp_release() < "27" do
        assert msg =~ "[info] Child :task of Supervisor #PID<"
      else
        assert msg =~ "[debug] Child :task of Supervisor #PID<"
      end

      assert msg =~ " (Supervisor.Default) started"
    end

    test "supervisor progress report failed to start child", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.supervisor_progress_report(:failed_to_start_child)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] Child :task of Supervisor #PID<"
      assert msg =~ " (Supervisor.Default) failed to start"
    end

    @tag level: :error
    test "supervisor progress report child terminated", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.supervisor_progress_report(:child_terminated)
      LoggerHandlerKit.Assert.assert_logged(ref)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg1}
      assert_receive {^io_ref, msg2}
      msg = msg1 <> msg2
      assert msg =~ "[error] Child :task of Supervisor #PID"
      assert msg =~ " (Supervisor.Default) terminated"
      assert msg =~ " (Supervisor.Default) caused shutdown"
      assert msg =~ "** (exit) :reached_max_restart_intensity"
    end
  end

  describe "Metadata" do
    test "nil", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:boolean)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "extra=true"
    end

    test "string", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:string)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "extra=hello"
    end

    test "binary", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:binary)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "extra=\x01\x02\x03"
    end

    test "atom", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:atom)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "extra=foo"
    end

    test "integer", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:integer)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "extra=42"
    end

    test "datetime", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:datetime)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "extra=2025-06-01 12:34:56.000Z"
    end

    test "struct", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:struct)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      # default formatter skips structs that do not implement String.Chars protocol 
      refute msg =~ "extra"
    end

    test "tuple", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:tuple)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      # default formatter skips tuples 
      refute msg =~ "extra"
    end

    test "keyword", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:keyword)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      # default formatter skips keyword lists 
      refute msg =~ "extra"
    end

    test "improper keyword", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:improper_keyword)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      # default formatter skips keyword lists 
      refute msg =~ "extra"
    end

    test "fake keyword", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:fake_keyword)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      # default formatter skips keyword lists 
      refute msg =~ "extra"
    end

    test "list", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:list)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      # default formatter skips all lists in fact 
      refute msg =~ "extra"
    end

    test "improper list", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:improper_list)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      # default formatter skips all lists in fact 
      refute msg =~ "extra"
    end

    test "map", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:map)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      # default formatter skips maps 
      refute msg =~ "extra"
    end

    test "function", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:function)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      # default formatter skips functions 
      refute msg =~ "extra"
    end

    test "anonymous function", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:anonymous_function)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      # default formatter skips functions 
      refute msg =~ "extra"
    end

    test "pid", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:pid)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ ~r"extra=<\d+\.\d+\.\d+>"
    end

    test "ref", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:ref)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ ~r"extra=<\d+.\d+\.\d+\.\d+>"
    end

    test "port", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:port)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ ~r"extra=<\d+.\d+>"
    end

    test "all", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.metadata_serialization(:all)
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      refute msg =~ "extra"
    end
  end

  describe "Plug" do
    @describetag level: :error

    test "Bandit: plug exception", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.plug_error(:exception, Bandit)
      LoggerHandlerKit.Assert.assert_logged(ref)
      assert_receive {^io_ref, msg}
      assert msg =~ "[error] ** (RuntimeError) oops"
    end

    test "Bandit: plug throw", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.plug_error(:throw, Bandit)
      LoggerHandlerKit.Assert.assert_logged(ref)
      assert_receive {^io_ref, msg}
      assert msg =~ "[error] ** (throw) \"catch!\""
    end

    test "Bandit: plug exit", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.plug_error(:exit, Bandit)
      LoggerHandlerKit.Assert.assert_logged(ref)
      assert_receive {^io_ref, msg}
      assert msg =~ "[error] ** (exit) \"i quit\""
    end

    test "Cowboy: plug exception", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.plug_error(:exception, Plug.Cowboy)
      LoggerHandlerKit.Assert.assert_logged(ref)
      assert_receive {^io_ref, msg}
      assert msg =~ "running LoggerHandlerKit.Plug"
      assert msg =~ "Server: localhost:8001"
      assert msg =~ "Request: GET /exception"
      assert msg =~ "(exit) an exception was raised:"
      assert msg =~ "** (RuntimeError) oops"
    end

    test "Cowboy: plug throw", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.plug_error(:throw, Plug.Cowboy)
      LoggerHandlerKit.Assert.assert_logged(ref)
      assert_receive {^io_ref, msg}
      assert msg =~ "running LoggerHandlerKit.Plug"
      assert msg =~ "Server: localhost:8001"
      assert msg =~ "Request: GET /throw"
      assert msg =~ "(exit) an exception was raised:"
      assert msg =~ "** (ErlangError) Erlang error: {:nocatch, \"catch!\"}"
    end

    test "Cowboy: plug exit", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.plug_error(:exit, Plug.Cowboy)
      LoggerHandlerKit.Assert.assert_logged(ref)
      assert_receive {^io_ref, msg}
      assert msg =~ "running LoggerHandlerKit.Plug"
      assert msg =~ "Server: localhost:8001"
      assert msg =~ "Request: GET /exit"
      assert msg =~ "** (exit) \"i quit\""
    end
  end
end
