defmodule Extunnel.ClientUtils do
  def connect_to_remote do
    remote_addr = Application.get_env(:extunnel, :server_addr)
    remote_port = Application.get_env(:extunnel, :server_port)
    {:ok, addr} = :inet.getaddr(String.to_atom(remote_addr), :inet)

    :gen_tcp.connect(addr, remote_port, [:binary, {:active, :once}, {:packet, 4}])
  end
end
