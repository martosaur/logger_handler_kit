# Plug Integration

`Plug` integration is the most common "addon" for
[logging](https://hexdocs.pm/sentry/setup-with-plug-and-phoenix.html)
[libraries](https://hexdocs.pm/honeybadger/Honeybadger.Plug.html)
[by](https://github.com/appsignal/appsignal-elixir-plug)
[far](https://hexdocs.pm/error_tracker/ErrorTracker.Integrations.Plug.html).
There are two reasons for this.

## 1. Metadata

`Plug.Conn` is a treasure trove of useful metadata that makes understanding
errors much easier. Even basic information like request path and user-agent can
make a huge difference in debugging. To take advantage of this rich context and
save developers effort, logging libraries typically provide a plug module that
you can drop into your router. This plug automatically extracts relevant
connection data and adds it to logger metadata. Any errors logged later in the
same process will inherit this context.

## 2. Error Handling

Setting metadata from `conn` is straightforward, why do a lot of Plug
integration modules consist largely of macros?

For a long time, `Cowboy` was _the_ web server for Elixir applications, and it
has one significant quirk: Cowboy logs errors from a different process than the
one that actually handled the request. Remember our earlier point?

> Any errors logged later in the same process will inherit this context.

Well, for Cowboy errors, all the lovely metadata will be gone. That's why Plug
integration modules use macros: they wrap plug execution in a way that allows
them to log the error themselves while in the process with access to metadata.
And this is also the reason why virtually every library excludes logs coming
from the `:cowboy` domain - that is, to avoid duplicates.

These days, custom error handling is hardly necessary. `Bandit` web server is
the new default and it executes requests and logs errors in the same process.
But the Cowboy situation is better too. `Plug.Cowboy` adapter comes with a
translator that ensures the `conn` struct is available in the log metadata, so a
logger handler can extract all the metadata from it again.

## Testing

LoggerHandlerKit comes with a `LoggerHandlerKit.Act.plug_error/3` test case to
help you check how plug errors will look when logged by your handler.