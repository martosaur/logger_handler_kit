defmodule LoggerHandlerKit.GenStatem do
  @moduledoc """
  A very simple GenStatem module which only purpose is to crash in a way that tests want it too.

  Is also propagates `$callers` to facilitate proper caller tracking.

  For usage examples check `LoggerHandlerKit.Act.gen_statem_crash/1`.
  """
  @behaviour :gen_statem

  def start(name \\ nil, args) do
    callers = Process.get(:"$callers", [])

    if name do
      :gen_statem.start(name, __MODULE__, {[self() | callers], args}, [])
    else
      :gen_statem.start(__MODULE__, {[self() | callers], args}, [])
    end
  end

  @impl :gen_statem
  def callback_mode, do: :state_functions

  @impl :gen_statem
  def init({callers, args}) do
    Process.put(:"$callers", callers)
    {:ok, :started, args}
  end

  def started({:call, _}, {:run, fun}, _), do: fun.()
end
