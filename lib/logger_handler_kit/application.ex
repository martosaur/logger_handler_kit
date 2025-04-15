defmodule LoggerHandlerKit.Application do
  @moduledoc false
  use Application

  def start(_, _) do
    children = [
      %{
        id: LoggerHandlerKit,
        type: :worker,
        start: {LoggerHandlerKit.Arrange, :start_link_ownership, []}
      }
    ]

    Supervisor.start_link(children, name: LoggerHandlerKit.Supervisor, strategy: :one_for_one)
  end
end
