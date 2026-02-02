defmodule AiTipsWeb.PageController do
  use AiTipsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
