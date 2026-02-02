defmodule PdfTipsElixirWeb.PageController do
  use PdfTipsElixirWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
