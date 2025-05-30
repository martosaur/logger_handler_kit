# Unhandled Errors

Logging services commonly distinguish between handled and unhandled errors. 
Unhandled errors are considered unexpected and receive special treatment: they 
are fingerprinted, aggregated, tracked for resolution, and, most importantly,
trigger user notifications.

Elixir does not have an explicit concept of an unhandled error. From the logger
perspective, an unhandled error looks like a log event and goes through the same
pipeline as other log events. Every logging service must therefore come up with its
own definition of unhandled errors and ways to identify them. Fortunately, there is
one useful trick for this.

## `crash_reason` metadata

Even though Elixir doesn't have a strict definition for which logs can be
considered unhandled, it helpfully puts a special [`crash_reason` key](`Logger#module-metadata`) into
log metadata for events that either resulted in or could result in some sort of 
process crash. This is done by `Logger.Translator` and is possible because
`Logger.Translator` holds a catalogue of common error reports and knows when to
enrich them with `crash_reason`. Thanks, `Logger.Translator`!

Looking for `crash_reason` is the simplest way to know if an error is unhandled.
However, be aware that `crash_reason` can be set manually by application code.
In this case, it isn't _truly_ unhandled. Still, if somebody explicitly _made it
look unhandled_, there's really no reason to treat it differently.

Below is an example showing how to report a handled error with `crash_reason`:

```elixir
defmodule Example do
  require Logger

  def handle_all(fun) do
    try do
      fun.()
    catch
      kind, reason ->
        stacktrace = __STACKTRACE__
        normalized = Exception.normalize(kind, reason, stacktrace)
        reason = if kind == :throw, do: {:nocatch, reason}, else: normalized
        
        Exception.format(kind, normalized, stacktrace)
        |> Logger.error(crash_reason: {reason, stacktrace}) 
    end
  end
end
```

<!-- tabs-open -->

### Exception

```elixir
iex> Example.handle_all(fn -> raise "foo" end)
12:32:24.703 [error] ** (RuntimeError) foo
    iex:3: (file)
    (elixir 1.18.3) src/elixir.erl:386: :elixir.eval_external_handler/3
    logger.exs:6: Example.handle_all/1
    (elixir 1.18.3) src/elixir.erl:386: :elixir.eval_external_handler/3
    (stdlib 6.2.2) erl_eval.erl:919: :erl_eval.do_apply/7
    (elixir 1.18.3) src/elixir.erl:364: :elixir.eval_forms/4
    (elixir 1.18.3) lib/module/parallel_checker.ex:120: Module.ParallelChecker.verify/1
    (iex 1.18.3) lib/iex/evaluator.ex:336: IEx.Evaluator.eval_and_inspect/3

:ok
```

Log event:

```elixir
%{
  meta: %{
    line: 12,
    pid: #PID<0.117.0>,
    time: 1748547144703394,
    file: ~c"/Users/user/example.exs",
    gl: #PID<0.70.0>,
    domain: [:elixir],
    mfa: {Example, :handle_all, 1},
    crash_reason: {%RuntimeError{message: "foo"},
     [
       {:elixir_eval, :__FILE__, 1, [file: ~c"iex", line: 3]},
       {:elixir, :eval_external_handler, 3,
        [file: ~c"src/elixir.erl", line: 386, error_info: %{module: Exception}]},
       {Example, :handle_all, 1, [file: ~c"logger.exs", line: 6]},
       {:elixir, :eval_external_handler, 3,
        [file: ~c"src/elixir.erl", line: 386]},
       {:erl_eval, :do_apply, 7, [file: ~c"erl_eval.erl", line: 919]},
       {:elixir, :eval_forms, 4, [file: ~c"src/elixir.erl", line: 364]},
       {Module.ParallelChecker, :verify, 1,
        [file: ~c"lib/module/parallel_checker.ex", line: 120]},
       {IEx.Evaluator, :eval_and_inspect, 3,
        [file: ~c"lib/iex/evaluator.ex", line: 336]}
     ]}
  },
  msg: {:string,
   "** (RuntimeError) foo\n    iex:3: (file)\n    (elixir 1.18.3) src/elixir.erl:386: :elixir.eval_external_handler/3\n    logger.exs:6: Example.handle_all/1\n    (elixir 1.18.3) src/elixir.erl:386: :elixir.eval_external_handler/3\n    (stdlib 6.2.2) erl_eval.erl:919: :erl_eval.do_apply/7\n    (elixir 1.18.3) src/elixir.erl:364: :elixir.eval_forms/4\n    (elixir 1.18.3) lib/module/parallel_checker.ex:120: Module.ParallelChecker.verify/1\n    (iex 1.18.3) lib/iex/evaluator.ex:336: IEx.Evaluator.eval_and_inspect/3\n"},
  level: :error
}
```

### Throw

```elixir
iex> Example.handle_all(fn -> throw "catch!" end)
12:37:38.382 [error] ** (throw) "catch!"
    iex:4: (file)
    (elixir 1.18.3) src/elixir.erl:386: :elixir.eval_external_handler/3
    logger.exs:6: Example.handle_all/1
    (elixir 1.18.3) src/elixir.erl:386: :elixir.eval_external_handler/3
    (stdlib 6.2.2) erl_eval.erl:919: :erl_eval.do_apply/7
    (elixir 1.18.3) src/elixir.erl:364: :elixir.eval_forms/4
    (elixir 1.18.3) lib/module/parallel_checker.ex:120: Module.ParallelChecker.verify/1
    (iex 1.18.3) lib/iex/evaluator.ex:336: IEx.Evaluator.eval_and_inspect/3

:ok
```

Log event:

```elixir
%{
  meta: %{
    line: 14,
    pid: #PID<0.117.0>,
    time: 1748558079155346,
    file: ~c"/Users/user/example.exs",
    gl: #PID<0.70.0>,
    domain: [:elixir],
    mfa: {Example, :handle_all, 1},
    crash_reason: {{:nocatch, "catch!"},
     [
       {:elixir_eval, :__FILE__, 1, [file: ~c"iex", line: 6]},
       {:elixir, :eval_external_handler, 3,
        [file: ~c"src/elixir.erl", line: 386]},
       {Example, :handle_all, 1, [file: ~c"logger.exs", line: 6]},
       {:elixir, :eval_external_handler, 3,
        [file: ~c"src/elixir.erl", line: 386]},
       {:erl_eval, :do_apply, 7, [file: ~c"erl_eval.erl", line: 919]},
       {:elixir, :eval_forms, 4, [file: ~c"src/elixir.erl", line: 364]},
       {Module.ParallelChecker, :verify, 1,
        [file: ~c"lib/module/parallel_checker.ex", line: 120]},
       {IEx.Evaluator, :eval_and_inspect, 3,
        [file: ~c"lib/iex/evaluator.ex", line: 336]}
     ]}
  },
  msg: {:string,
   "** (throw) \"catch!\"\n    iex:6: (file)\n    (elixir 1.18.3) src/elixir.erl:386: :elixir.eval_external_handler/3\n    logger.exs:6: Example.handle_all/1\n    (elixir 1.18.3) src/elixir.erl:386: :elixir.eval_external_handler/3\n    (stdlib 6.2.2) erl_eval.erl:919: :erl_eval.do_apply/7\n    (elixir 1.18.3) src/elixir.erl:364: :elixir.eval_forms/4\n    (elixir 1.18.3) lib/module/parallel_checker.ex:120: Module.ParallelChecker.verify/1\n    (iex 1.18.3) lib/iex/evaluator.ex:336: IEx.Evaluator.eval_and_inspect/3\n"},
  level: :error
}
```

### Exit

```elixir
iex> Example.handle_all(fn -> exit("i quit") end)
12:38:42.709 [error] ** (exit) "i quit"
    iex:5: (file)
    (elixir 1.18.3) src/elixir.erl:386: :elixir.eval_external_handler/3
    logger.exs:6: Example.handle_all/1
    (elixir 1.18.3) src/elixir.erl:386: :elixir.eval_external_handler/3
    (stdlib 6.2.2) erl_eval.erl:919: :erl_eval.do_apply/7
    (elixir 1.18.3) src/elixir.erl:364: :elixir.eval_forms/4
    (elixir 1.18.3) lib/module/parallel_checker.ex:120: Module.ParallelChecker.verify/1
    (iex 1.18.3) lib/iex/evaluator.ex:336: IEx.Evaluator.eval_and_inspect/3

:ok
```

Log event:

```elixir
%{
  meta: %{
    line: 12,
    pid: #PID<0.117.0>,
    time: 1748547522709480,
    file: ~c"/Users/user/example.exs",
    gl: #PID<0.70.0>,
    domain: [:elixir],
    mfa: {Example, :handle_all, 1},
    crash_reason: {"i quit",
     [
       {:elixir_eval, :__FILE__, 1, [file: ~c"iex", line: 5]},
       {:elixir, :eval_external_handler, 3,
        [file: ~c"src/elixir.erl", line: 386]},
       {Example, :handle_all, 1, [file: ~c"logger.exs", line: 6]},
       {:elixir, :eval_external_handler, 3,
        [file: ~c"src/elixir.erl", line: 386]},
       {:erl_eval, :do_apply, 7, [file: ~c"erl_eval.erl", line: 919]},
       {:elixir, :eval_forms, 4, [file: ~c"src/elixir.erl", line: 364]},
       {Module.ParallelChecker, :verify, 1,
        [file: ~c"lib/module/parallel_checker.ex", line: 120]},
       {IEx.Evaluator, :eval_and_inspect, 3,
        [file: ~c"lib/iex/evaluator.ex", line: 336]}
     ]}
  },
  msg: {:string,
   "** (exit) \"i quit\"\n    iex:5: (file)\n    (elixir 1.18.3) src/elixir.erl:386: :elixir.eval_external_handler/3\n    logger.exs:6: Example.handle_all/1\n    (elixir 1.18.3) src/elixir.erl:386: :elixir.eval_external_handler/3\n    (stdlib 6.2.2) erl_eval.erl:919: :erl_eval.do_apply/7\n    (elixir 1.18.3) src/elixir.erl:364: :elixir.eval_forms/4\n    (elixir 1.18.3) lib/module/parallel_checker.ex:120: Module.ParallelChecker.verify/1\n    (iex 1.18.3) lib/iex/evaluator.ex:336: IEx.Evaluator.eval_and_inspect/3\n"},
  level: :error
}
```

<!-- tabs-close -->

None of those errors actually crashed anything, but we deliberately logged them
as if they did. This is often done by libraries when they want to report errors
in user code, but cannot let it crash their process.
[`Bandit`](https://github.com/mtrudel/bandit/blob/b8bf2bc76c1f49885fed5c2e68111e55b9e84e25/lib/bandit/pipeline.ex#L242-L243)
is a good example. If you are a library author and want to handle errors that
originate in the client's code without crashing the process, make sure to be a
good citizen and put `crash_reason` into your log message!

> #### `{:nocatch, term}` {: .tip}
>
> The convention requires the throw value to be wrapped in a `{:nocatch, term}`
> tuple. This helps distinguish it from the exit reason.

