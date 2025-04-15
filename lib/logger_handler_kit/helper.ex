defmodule LoggerHandlerKit.Helper do
  @doc """
  A helper function for when we want to run an anonymous function, but the interface
  requires a MFA tuple.
  """
  def run(fun), do: fun.()
end
