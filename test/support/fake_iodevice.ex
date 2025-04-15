defmodule FakeIODevice do
  @moduledoc """
  A genserver that partially implements [Erlang I/O protocol](https://www.erlang.org/doc/apps/stdlib/io_protocol)
  and can be used as IO Device.

  We use it as an IO device for `:logger_std_h` handler in "default logger tests". This way we can
  ensure handler output does not pollute tests output and is readily available for assertions.
  """
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(%{test_pid: test_pid, ref: ref}) do
    {:ok, %{test_pid: test_pid, ref: ref}}
  end

  @impl GenServer
  def handle_info({:io_request, from, ref, {:put_chars, :unicode, characters}}, state) do
    send(from, {:io_reply, ref, :ok})
    send(state.test_pid, {state.ref, characters})
    {:noreply, state}
  end
end
