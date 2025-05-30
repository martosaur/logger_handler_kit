# Log Translation

Elixir and Erlang are different languages, but Elixir runs on the Erlang
platform and it doesn't take much time until the platform starts to manifest
itself. A lot of common errors originate in Erlang and if printed as-is, look
foreign in the context of Elixir applications. To avoid this, Elixir performs
something called log translation. This is one of the main functions of `Logger`
applications Compare these two GenServer errors, with and without translation:

<!-- tabs-open -->

### With Translation

```text
13:43:32.538 [error] GenServer #PID<0.198.0> terminating
** (RuntimeError) oops
    (logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:528: anonymous fn/0 in LoggerHandlerKit.Act.genserver_crash/1
    (stdlib 6.2.2) gen_server.erl:2381: :gen_server.try_handle_call/4
    (stdlib 6.2.2) gen_server.erl:2410: :gen_server.handle_msg/6
    (stdlib 6.2.2) proc_lib.erl:329: :proc_lib.init_p_do_apply/3
Last message (from #PID<0.197.0>): {:run, #Function<16.413966/0 in LoggerHandlerKit.Act.genserver_crash/1>}
State: nil
Client #PID<0.197.0> is alive

    (stdlib 6.2.2) gen.erl:260: :gen.do_call/4
    (elixir 1.19.0-dev) lib/gen_server.ex:1139: GenServer.call/3
    (logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:528: LoggerHandlerKit.Act.genserver_crash/1
    (elixir 1.19.0-dev) src/elixir.erl:363: :elixir.eval_external_handler/3
    (stdlib 6.2.2) erl_eval.erl:919: :erl_eval.do_apply/7
    (elixir 1.19.0-dev) src/elixir.erl:341: :elixir.eval_forms/4
    (elixir 1.19.0-dev) lib/module/parallel_checker.ex:141: Module.ParallelChecker.verify/1
    (iex 1.19.0-dev) lib/iex/evaluator.ex:340: IEx.Evaluator.eval_and_inspect/3
```

### Without Translation

```text
13:44:53.011 [error] ** Generic server <0.199.0> terminating
** Last message in was {run,#Fun<Elixir.LoggerHandlerKit.Act.16.413966>}
** When Server state == nil
** Reason for termination ==
** {#{message => <<"oops">>,'__struct__' => 'Elixir.RuntimeError',
      '__exception__' => true},
    [{'Elixir.LoggerHandlerKit.Act','-genserver_crash/1-fun-0-',0,
         [{file,"lib/logger_handler_kit/act.ex"},
          {line,528},
          {error_info,#{module => 'Elixir.Exception'}}]},
     {gen_server,try_handle_call,4,[{file,"gen_server.erl"},{line,2381}]},
     {gen_server,handle_msg,6,[{file,"gen_server.erl"},{line,2410}]},
     {proc_lib,init_p_do_apply,3,[{file,"proc_lib.erl"},{line,329}]}]}
** Client <0.197.0> stacktrace
** [{gen,do_call,4,[{file,"gen.erl"},{line,260}]},
    {'Elixir.GenServer',call,3,[{file,"lib/gen_server.ex"},{line,1139}]},
    {'Elixir.LoggerHandlerKit.Act',genserver_crash,1,
                                   [{file,"lib/logger_handler_kit/act.ex"},
                                    {line,528}]},
    {elixir,eval_external_handler,3,[{file,"src/elixir.erl"},{line,363}]},
    {erl_eval,do_apply,7,[{file,"erl_eval.erl"},{line,919}]},
    {elixir,eval_forms,4,[{file,"src/elixir.erl"},{line,341}]},
    {'Elixir.Module.ParallelChecker',verify,1,
                                     [{file,"lib/module/parallel_checker.ex"},
                                      {line,141}]},
    {'Elixir.IEx.Evaluator',eval_and_inspect,3,
                            [{file,"lib/iex/evaluator.ex"},{line,340}]}]


13:44:53.016 [error]   crasher:
    initial call: 'Elixir.LoggerHandlerKit.GenServer':init/1
    pid: <0.199.0>
    registered_name: []
    exception error: #Elixir.RuntimeError
      in function  'Elixir.LoggerHandlerKit.Act':'-genserver_crash/1-fun-0-'/0 (lib/logger_handler_kit/act.ex, line 528)
         *** oops
      in call from gen_server:try_handle_call/4 (gen_server.erl, line 2381)
      in call from gen_server:handle_msg/6 (gen_server.erl, line 2410)
    ancestors: [<0.197.0>,<0.98.0>]
    message_queue_len: 0
    messages: []
    links: []
    dictionary: [{'$callers',[<0.197.0>]}]
    trap_exit: false
    status: running
    heap_size: 6772
    stack_size: 29
    reductions: 19158
  neighbours: []
```

<!-- tabs-close -->

It's very clear how important translation is for people who are fluent primarily
in Elixir.

## Translation is a Filter

Log translation is implemented as a primary filter, which means it will be
called before handlers and any handler-specific filters. Remember that filters
and logger configuration in general can be altered by users, although it's
somewhat uncommon to remove or modify the `logger_translator` specifically.

To better visualize this, here is where the translation happens:

```elixir
iex(1)> :logger.get_primary_config()
%{
  level: :debug,
  filter_default: :log,
  filters: [
    # Here it is! Translation filter
    logger_translator: {&Logger.Utils.translator/2,
     %{otp: true, sasl: false, translators: [{Logger.Translator, :translate}]}},
    logger_process_level: {&Logger.Utils.process_level/2, []}
  ],
  metadata: %{}
}
```

## 1.18 vs 1.19+

Before Elixir 1.19, log translation used to _replace_ the original Erlang
structured report with an unstructured log message. If a handler wanted to access
some of the data in the original report, it had to parse the log message.
Starting from Elixir 1.19, translation is _inserted into_ the report, thus
making the original report accessible to the handlers. Here is an example:

<!-- tabs-open -->

### Before Translation

```elixir
%{
  meta: %{
    error_logger: %{tag: :error_report, type: :crash_report},
    line: 950,
    pid: #PID<0.203.0>,
    time: 1746910751187661,
    file: ~c"proc_lib.erl",
    gl: #PID<0.70.0>,
    domain: [:otp, :sasl],
    logger_formatter: %{title: ~c"CRASH REPORT"},
    mfa: {:proc_lib, :crash_report, 4},
    report_cb: &:proc_lib.report_cb/2
  },
  msg: {:report,
   %{
     label: {:proc_lib, :crash},
     report: [
       [
         initial_call: {LoggerHandlerKit.GenServer, :init, [:Argument__1]},
         pid: #PID<0.203.0>,
         registered_name: [],
         process_label: :undefined,
         error_info: {:error, %RuntimeError{message: "oops"},
          [
            {LoggerHandlerKit.Act, :"-genserver_crash/1-fun-0-", 0,
             [
               file: ~c"lib/logger_handler_kit/act.ex",
               line: 528,
               error_info: %{module: Exception}
             ]},
            {:gen_server, :try_handle_call, 4,
             [file: ~c"gen_server.erl", line: 2381]},
            {:gen_server, :handle_msg, 6,
             [file: ~c"gen_server.erl", line: 2410]},
            {:proc_lib, :init_p_do_apply, 3,
             [file: ~c"proc_lib.erl", line: 329]}
          ]},
         ancestors: [#PID<0.197.0>, #PID<0.98.0>],
         message_queue_len: 0,
         messages: [],
         links: [],
         dictionary: ["$callers": [#PID<0.197.0>]],
         trap_exit: false,
         status: :running,
         heap_size: 1598,
         stack_size: 29,
         reductions: 28455
       ],
       []
     ]
   }},
  level: :error
}
```

### 1.18 Translation

```elixir
%{
  meta: %{
    error_logger: %{tag: :error, report_cb: &:gen_server.format_log/1},
    line: 2646,
    pid: #PID<0.1105.0>,
    time: 1746911049539570,
    file: ~c"gen_server.erl",
    gl: #PID<0.70.0>,
    domain: [:otp],
    report_cb: &:gen_server.format_log/2,
    mfa: {:gen_server, :error_info, 8},
    crash_reason: {%RuntimeError{message: "oops"},
     [
       {LoggerHandlerKit.Act, :"-genserver_crash/1-fun-0-", 0,
        [
          file: ~c"lib/logger_handler_kit/act.ex",
          line: 528,
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
       "#PID<0.1105.0>",
       " terminating",
       [
         [10 | "** (RuntimeError) oops"],
         ["\n    " |
          "(logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:528: anonymous fn/0 in LoggerHandlerKit.Act.genserver_crash/1"],
         ["\n    " |
          "(stdlib 6.2.2) gen_server.erl:2381: :gen_server.try_handle_call/4"],
         ["\n    " |
          "(stdlib 6.2.2) gen_server.erl:2410: :gen_server.handle_msg/6"],
         ["\n    " |
          "(stdlib 6.2.2) proc_lib.erl:329: :proc_lib.init_p_do_apply/3"]
       ],
       [],
       "\nLast message",
       [" (from ", "#PID<0.1099.0>", ")"],
       ": ",
       "{:run, #Function<16.413966/0 in LoggerHandlerKit.Act.genserver_crash/1>}"
     ],
     "\nState: ",
     "nil",
     "\nClient ",
     "#PID<0.1099.0>",
     " is alive\n",
     ["\n    " | "(stdlib 6.2.2) gen.erl:260: :gen.do_call/4"],
     ["\n    " | "(elixir 1.18.3) lib/gen_server.ex:1125: GenServer.call/3"],
     ["\n    " |
      "(logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:528: LoggerHandlerKit.Act.genserver_crash/1"],
     ["\n    " |
      "(elixir 1.18.3) src/elixir.erl:386: :elixir.eval_external_handler/3"],
     ["\n    " | "(stdlib 6.2.2) erl_eval.erl:919: :erl_eval.do_apply/7"],
     ["\n    " | "(elixir 1.18.3) src/elixir.erl:364: :elixir.eval_forms/4"],
     ["\n    " |
      "(elixir 1.18.3) lib/module/parallel_checker.ex:120: Module.ParallelChecker.verify/1"],
     ["\n    " |
      "(iex 1.18.3) lib/iex/evaluator.ex:336: IEx.Evaluator.eval_and_inspect/3"]
   ]},
  level: :error
}
```

### 1.19 Translation

```elixir
%{
  meta: %{
    error_logger: %{tag: :error, report_cb: &:gen_server.format_log/1},
    line: 2646,
    pid: #PID<0.205.0>,
    time: 1746910905177484,
    file: ~c"gen_server.erl",
    gl: #PID<0.70.0>,
    domain: [:otp],
    mfa: {:gen_server, :error_info, 8},
    report_cb: &Logger.Utils.translated_cb/1,
    crash_reason: {%RuntimeError{message: "oops"},
     [
       {LoggerHandlerKit.Act, :"-genserver_crash/1-fun-0-", 0,
        [
          file: ~c"lib/logger_handler_kit/act.ex",
          line: 528,
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
     name: #PID<0.205.0>,
     reason: {%RuntimeError{message: "oops"},
      [
        {LoggerHandlerKit.Act, :"-genserver_crash/1-fun-0-", 0,
         [
           file: ~c"lib/logger_handler_kit/act.ex",
           line: 528,
           error_info: %{module: Exception}
         ]},
        {:gen_server, :try_handle_call, 4,
         [file: ~c"gen_server.erl", line: 2381]},
        {:gen_server, :handle_msg, 6, [file: ~c"gen_server.erl", line: 2410]},
        {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 329]}
      ]},
     log: [],
     state: nil,
     process_label: :undefined,
     last_message: {:run,
      #Function<16.413966/0 in LoggerHandlerKit.Act.genserver_crash/1>},
     client_info: {#PID<0.197.0>,
      {#PID<0.197.0>,
       [
         {:gen, :do_call, 4, [file: ~c"gen.erl", line: 260]},
         {GenServer, :call, 3, [file: ~c"lib/gen_server.ex", line: 1139]},
         {LoggerHandlerKit.Act, :genserver_crash, 1,
          [file: ~c"lib/logger_handler_kit/act.ex", line: 528]},
         {:elixir, :eval_external_handler, 3,
          [file: ~c"src/elixir.erl", line: 363]},
         {:erl_eval, :do_apply, 7, [file: ~c"erl_eval.erl", line: 919]},
         {:elixir, :eval_forms, 4, [file: ~c"src/elixir.erl", line: 341]},
         {Module.ParallelChecker, :verify, 1,
          [file: ~c"lib/module/parallel_checker.ex", line: 141]},
         {IEx.Evaluator, :eval_and_inspect, 3,
          [file: ~c"lib/iex/evaluator.ex", line: 340]}
       ]}},
     elixir_translation: [
       [
         "GenServer ",
         "#PID<0.205.0>",
         " terminating",
         [
           [10 | "** (RuntimeError) oops"],
           ["\n    " |
            "(logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:528: anonymous fn/0 in LoggerHandlerKit.Act.genserver_crash/1"],
           ["\n    " |
            "(stdlib 6.2.2) gen_server.erl:2381: :gen_server.try_handle_call/4"],
           ["\n    " |
            "(stdlib 6.2.2) gen_server.erl:2410: :gen_server.handle_msg/6"],
           ["\n    " |
            "(stdlib 6.2.2) proc_lib.erl:329: :proc_lib.init_p_do_apply/3"]
         ],
         [],
         "\nLast message",
         [" (from ", "#PID<0.197.0>", ")"],
         ": ",
         "{:run, #Function<16.413966/0 in LoggerHandlerKit.Act.genserver_crash/1>}"
       ],
       "\nState: ",
       "nil",
       "\nClient ",
       "#PID<0.197.0>",
       " is alive\n",
       ["\n    " | "(stdlib 6.2.2) gen.erl:260: :gen.do_call/4"],
       ["\n    " |
        "(elixir 1.19.0-dev) lib/gen_server.ex:1139: GenServer.call/3"],
       ["\n    " |
        "(logger_handler_kit 0.1.0) lib/logger_handler_kit/act.ex:528: LoggerHandlerKit.Act.genserver_crash/1"],
       ["\n    " |
        "(elixir 1.19.0-dev) src/elixir.erl:363: :elixir.eval_external_handler/3"],
       ["\n    " | "(stdlib 6.2.2) erl_eval.erl:919: :erl_eval.do_apply/7"],
       ["\n    " |
        "(elixir 1.19.0-dev) src/elixir.erl:341: :elixir.eval_forms/4"],
       ["\n    " |
        "(elixir 1.19.0-dev) lib/module/parallel_checker.ex:141: Module.ParallelChecker.verify/1"],
       ["\n    " |
        "(iex 1.19.0-dev) lib/iex/evaluator.ex:340: IEx.Evaluator.eval_and_inspect/3"]
     ]
   }},
  level: :error
}
```

<!-- tabs-close -->

## More Than Translation

### Enforcing `handle_*_reports` configuration options

In addition to translating logs, the `logger_translator` filter is also responsible
for enforcing the `handle_otp_reports` and `handle_sasl_reports` [configuration
options](https://hexdocs.pm/logger/Logger.html#module-boot-configuration). This
is worth keeping in mind and may come up during debugging. Trying to understand
which part of the system dropped an OTP log event may lead to the surprising
discovery that the logger translator did it.

### Populating `crash_reason`

Another important job of `Logger.Translator` is [populating the `crash_reason`
metadata](unhandled.md). This metadata key contains a `{reason, stacktrace}` tuple and serves
as an Elixir convention for marking log events that result from unhandled
exceptions, throws, or abnormal exits.