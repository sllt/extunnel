defmodule Extunnel.ServerWorker do
  use GenServer
  require Record
  @behaviour :ranch_protocol

  Record.defrecord :state, [key: :undefined, ref: :undefined, socket: :undefined,
            transport: :undefined, ok: :undefined, closed: :undefined,
            error: :undefined, remote: :undefined]
  @type state :: record(:state, key: String.t, ref: :ranch.ref,
      socket: any, transport: module, ok: any, closed: any, error: any,
      remote: :gen_tcp.socket | :undefined)

  @timeout 1000 * 60 * 10

  def start_link(ref, socket, transport, opts) do
    GenServer.start_link(__MODULE__, [ref, socket, transport, opts], [])
  end


  def init([ref, socket, transport, _opts]) do
    :erlang.put(:init, :true)
    key = Application.get_env(:extunnel, :key)
    {ok, closed, error} = transport.messages()

    :ok = transport.setopts(socket, [{:active, :once}, {:packet, 4}])
    
    s = state(key: key, ref: ref, socket: socket,
      transport: transport, ok: ok, closed: closed,
      error: error)
    {:ok, s, 0}
  end

  def handle_call(_request, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  # first message from client
  def handle_info({ok, socket, request},
    state(key: key, socket: socket,
      transport: transport, ok: ok, remote: :undefined) = s) do
    case connect_to_remote(request, key) do
      {:ok, remote} ->
        :ok = transport.setopts(socket, [{:active, :once}])
        {:noreply, state(s, remote: remote), @timeout}
      {:error, error} ->
        {:stop, error, s}
    end
  end

  # recv from client, then send to server
  def handle_info({ok, socket, request},
    state(key: key, socket: socket,
      transport: transport, ok: ok, remote: remote) = s) do
    {:ok, real_data} = Extunnel.Crypto.decrypt(key, request)
    case :gen_tcp.send(remote, real_data) do
      :ok ->
        :ok = transport.setopts(socket, [{:active, :once}])
        {:noreply, s, @timeout}
      {:error, error} ->
        {:stop, error, s}
    end
  end

  # recv from server, and send back to client
  def handle_info({:tcp, remote, response},
    state(key: key, socket: client,
      transport: transport, remote: remote) = s) do
    
    case transport.send(client, Extunnel.Crypto.encrypt(key, response)) do
      :ok ->
        :ok = :inet.setopts(remote, [{:active, :once}])
        {:noreply, s, @timeout}
      {:error, error} ->
        {:stop, error, s}
    end
  end

  def handle_info({closed, _}, state(closed: closed) = s), do: {:stop, :normal, s}
  def handle_info({error, _, reason}, state(error: error) = s), do: {:stop, reason, s}
  def handle_info({:tcp_closed, _}, s), do: {:stop, :normal, s}
  def handle_info({:tcp_error, _, reason}, s), do: {:stop, reason, s}
  def handle_info(:timeout, state(ref: ref) = s) do
    case :erlang.get(:init) do
      :true ->
        :ok = :ranch.accept_ack(ref)
        :erlang.erase(:init)
        {:noreply, s}
      :undefined ->
        {:stop, :normal, s} 
    end
  end

  def terminate(_reason, state(socket: socket, transport: transport,
    remote: remote)) do
    case :erlang.is_port(socket) do
      :true ->
        transport.close(socket)
      :false -> :ok
    end
    case is_port(remote) do
      :true ->
        :gen_tcp.close(remote)
      :false -> :ok
    end
  end

  def code_change(_old_vsn, s, _extra) do
    {:ok, s}
  end

  def connect_to_remote(data, key) do
    case Extunnel.Crypto.decrypt(key, data) do
      {:ok, real_data} ->
        {address, port} = :erlang.binary_to_term(real_data)
        connect_target(address, port)
      {:error, error} ->
        {:error, error}
    end
  end

  def connect_target(address, port) do
    connect_target(address, port, 2)
  end

  def connect_target(_,_,0), do: {:error, :connect_failure}
  def connect_target(address, port, retry_times) do
    case :gen_tcp.connect(Tuple.to_list(address), port, [:binary, {:active, :once}], 5000) do
      {:ok, target_socket} ->
        {:ok, target_socket}
      {:error, _error} ->
        connect_target(address, port, retry_times - 1)
    end
  end
end
