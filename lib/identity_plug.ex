defmodule MixDocker.IdentityPlug do
  import Plug.Conn
  alias Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn = %Conn{request_path: "/identity"}, identity_file: identity_file) do
    identity_file = identity_file |> String.replace("~", System.user_home)
    case File.read(identity_file) do
      {:ok, content} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, content)
      {:error, :enoent} ->
        send_resp(conn, 404, "not found")
      {:error, error} ->
        send_resp(conn, 500, :file.format_error(error))
    end
  end
  def call(conn, _) do
    send_resp(conn, 404, "not found")
  end
end