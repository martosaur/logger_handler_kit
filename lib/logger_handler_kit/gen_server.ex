defmodule LoggerHandlerKit.GenServer do
  @moduledoc """
  A very simple GenServer module which only purpose is to crash in a way that tests want it too.

  Is also propagates `$callers` to facilitate proper caller tracking.

  For usage examples check `LoggerHandlerKit.Act.genserver_crash/1`.
  """
  use GenServer

  def start(args, opts \\ []) do
    callers = Process.get(:"$callers") || []
    GenServer.start(__MODULE__, {[self() | callers], args}, opts)
  end

  @impl GenServer
  def init({callers, args}) do
    Process.put(:"$callers", callers)

    case args do
      {:run, fun} -> fun.()
      _ -> {:ok, args}
    end
  end

  @impl GenServer
  def handle_call({:run, fun}, from, state) when is_function(fun, 2), do: fun.(from, state)
  def handle_call({:run, fun}, _from, state) when is_function(fun, 1), do: fun.(state)
  def handle_call({:run, fun}, _from, _state), do: fun.()

  @impl GenServer
  def handle_cast({:run, fun}, _state), do: fun.()
end
