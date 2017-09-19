defmodule Extunnel do
  def start_server do
    {:ok, _} = Application.ensure_all_started(:extunnel)
    port = Application.get_env(:extunnel, :server_port)

    trans_opts = transport_opts(port)

    {:ok, _} = :ranch.start_listener(:extunnel_server,
          20,
          :ranch_tcp,
          trans_opts,
          Extunnel.ServerWorker, [])
  end

  def start_client do
    {:ok, _} = Application.ensure_all_started(:extunnel)
    port = Application.get_env(:extunnel, :client_port)
    trans_opts = transport_opts(port)
    {:ok, _} = :ranch.start_listener(:extunnel_client,
      20,
      :ranch_tcp,
      trans_opts,
      Extunnel.ClientWorker, [])
  end

  def transport_opts(port) do
    [{:port, port}, {:max_connections, :infinity}]
  end
end
