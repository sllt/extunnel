defmodule Extunnel.ClientWorker do
  use GenServer
  import Extunnel.Client

  @behaviour :ranch_protocol

  def start_link(ref, socket, transport, opts) do
    GenServer.start_link(__MODULE__, [ref, socket, transport, opts])
  end


  def init([ref, socket, transport, _opts]) do
    :erlang.put(:init, :true)
    key = Application.get_env(:extunnel, :key)
    {ok, closed, error} = transport.messages()

    :ok = transport.setopts(socket, [:binary, {:active, :once}, {:packet, :raw}])

    state = client(key: key, ref: ref, socket: socket,
      transport: transport, ok: ok, closed: closed,
      error: error, buffer: <<>>, keep_alive: false)
    {:ok, state, 0}
  end

  def handle_call(_request, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_request, state) do
    {:noreply, state}
  end


  def handle_info({ok, socket, data},
        client(socket: socket, transport: transport, ok: ok,
          protocol: :undefined) = state) do
      case detect_protocol(data) do
        {:ok, protocol_handler} ->
          state1 = client(state, protocol: protocol_handler)
          case protocol_handler.request(data, state1) do
            {:ok, state2} ->
              :ok = transport.setopts(socket, [{:active, :once}])
              {:noreply, state2}
            {:error, reason} ->
              {:stop, reason, state1}
          end
        {:error, reason} ->
          {:stop, reason, state}
      end
  end

  def handle_info({ok, socket, data},
    client(socket: socket, transport: transport,
      ok: ok, protocol: protocol) = state) do
    case protocol.request(data, state) do
      {:ok, state1} ->
        :ok = transport.setopts(socket, [{:active, :once}])
        {:noreply, state1}
      {:error, reason} ->
        {:stop, reason, state}
    end
  end

  def handle_info({:tcp, remote, data},
    client(key: key, socket: socket, transport: transport,
      remote: remote) = state) do
    {:ok, real_data} = Extunnel.Crypto.decrypt(key, data)
    :ok = transport.send(socket, real_data)
    :ok = :inet.setopts(remote, [{:active, :once}])
    {:noreply, state}
  end

  def handle_info({closed, _},
    client(closed: closed) = state) do
    {:stop, :normal, state}
  end

  def handle_info({error, _, reason},
    client(error: error) = state) do
    {:stop, reason, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _, reason}, state) do
    {:stop, reason, state}
  end

  def handle_info(:timeout, client(ref: ref) = state) do
    case :erlang.get(:init) do
      :true ->
        :ok = :ranch.accept_ack(ref)
        :erlang.erase(:init)
        {:noreply, state}
      :undefined ->
        {:stop, :normal, state}
    end
  end

  def terminate(_reason, client(socket: socket, transport: transport,
    remote: remote)) do
    case :erlang.is_port(socket) do
      :true ->
        transport.close(socket)
      :false ->
        :ok        
    end
    case :erlang.is_port(remote) do
      :true ->
        :gen_tcp.close(remote)
      :false ->
        :ok
    end
  end

  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  def detect_protocol(<<_head :: size(8), _rest :: binary >>) do
    {:ok, Extunnel.Socks}
  end
end
