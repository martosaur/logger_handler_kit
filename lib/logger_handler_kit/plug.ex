defmodule LoggerHandlerKit.Plug do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/exception" do
    raise "oops"
    conn
  end

  get "/throw" do
    throw("catch!")
    conn
  end

  get "/exit" do
    exit("i quit")
    conn
  end
end
