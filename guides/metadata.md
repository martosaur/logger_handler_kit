# Metadata

[Logger metadata](`Logger#module-metadata`) is structured data attached to log
messages. Metadata can be passed to `Logger` with the message:

```elixir
Logger.info("Hello", user_id: 123)
```

or set beforehand with `Logger.metadata/1`:

```elixir
Logger.metadata(user_id: 123)
```

> #### Not Just Keyword List {: .tip}
>
> Big Logger don't want you to know, but maps totally work as metadata too:
>
> ```elixir
> iex> Logger.metadata(%{hello: "world"})
> :ok
> iex> Logger.metadata()
> [hello: "world"]
> ```

Metadata is tricky to use correctly because it behaves very differently in
development versus production environments. In development, the default console
logger outputs minimal metadata, and even when configured to show more, console
space is limited, so developers are pushed to embed important data directly in
log messages. Production logging solutions, however, very much prefer structured
metadata for filtering and searching, paired with static log messages that
enable effective fingerprinting and grouping of similar events.

This guide focuses on the latter approach: using static log messages paired with
rich metadata:

```elixir
Logger.error("Unexpected API response", status_code: 422, user_id: 123)
```

When working with metadata, logging libraries typically grapple with two key
challenges: serialization and scrubbing.

## Serialization

Metadata can hold Elixir terms of any type, but to send them somewhere and
display them to users, they must be serialized. Unfortunately, there's no
universally good way to handle this! Elixir's default
`Logger.Formatter#module-metadata` supports only a handful of types. The
de-facto expectation, however, is that specialized logging libraries can handle
any term and display it reasonably well. Consequently, every logging library
implements a step where it makes the hard decisions about what to do with
tuples, structs, and other complex data types. This process is sometimes called
encoding or sanitization.

One solution that works well and can be easily integrated into your project is
the
[`LoggerJSON.Formatters.RedactorEncoder.encode/2`](https://hexdocs.pm/logger_json/LoggerJSON.Formatter.RedactorEncoder.html#encode/2)
function. It accepts any Elixir term and makes it JSON-serializable:

```elixir
iex> LoggerJSON.Formatter.RedactorEncoder.encode(%{tuple: {:ok, "foo"}, pid: self()}, [])
%{pid: "#PID<0.219.0>", tuple: [:ok, "foo"]}
```

## Scrubbing

Scrubbing is the process of removing sensitive fields from metadata. Data like
passwords, API keys, or credit card numbers should never be sent to your logging
service unnecessarily. While many logging services implement scrubbing on the
receiving end, some libraries handle this on the client side as well.

The challenge with scrubbing is that it must be configurable. Applications store
diverse types of secrets, and no set of default rules can catch them all.
Fortunately, the same solution used for serialization works here too.
[`LoggerJSON.Formatters.RedactorEncoder.encode/2`](https://hexdocs.pm/logger_json/LoggerJSON.Formatter.RedactorEncoder.html#encode/2)
accepts a list of "redactors" that will be called to scrub potentially sensitive
data. It includes a powerful
[`LoggerJSON.Redactors.RedactKeys`](https://hexdocs.pm/logger_json/LoggerJSON.Redactors.RedactKeys.html)
redactor that redacts all values stored under specified keys:

```elixir
iex> LoggerJSON.Formatter.RedactorEncoder.encode(
  %{user: "Marion", password: "SCP-3125"},
  [{LoggerJSON.Redactors.RedactKeys, ["password"]}]
)
%{user: "Marion", password: "[REDACTED]"}
```

## Conclusion

While [`LoggerJSON`](https://hex.pm/packages/logger_json)'s primary goal isn't to solve our metadata struggles, it
comes with a set of tools that can be very handy. Even if you don't want to
depend on it directly, it can provide you with a good starting point for your
own solution. And `LoggerHandlerKit.Act.metadata_serialization/1` can help you
with test cases!