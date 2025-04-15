defmodule LoggerHandlerKit.DefaultLoggerTest do
  use ExUnit.Case, async: true

  setup_all {LoggerHandlerKit.Arrange, :ensure_per_handler_translation}

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
        Map.merge(%{formatter: Logger.default_formatter()}, big_config_override)
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

    test "gen_statem crash exception", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.gen_statem_crash(:exception)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] :gen_statem #PID"
      assert msg =~ "** (RuntimeError) oops"
    end

    test "gen_statem crash exit", %{handler_ref: ref, io_ref: io_ref} do
      LoggerHandlerKit.Act.gen_statem_crash(:exit)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive {^io_ref, msg}
      assert msg =~ "[error] :gen_statem #PID"
      assert msg =~ "** (stop) \"i quit\""
    end

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
      assert msg =~ "[debug] Child :task of Supervisor #PID<"
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
end
