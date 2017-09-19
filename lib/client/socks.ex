defmodule Extunnel.Socks do
  import Extunnel.Client
  require Logger
  
  def detect_head(5), do: true
  def detect_head(_), do: false

  def request(data,
    client(key: key, socket: socket, transport: transport,
      remote: :undefined, buffer: buffer) = state) do
    data1 = <<buffer :: binary, data :: binary>>
    case find_target(data1) do
      {:ok, target, body, response} ->
        case Extunnel.ClientUtils.connect_to_remote() do
          {:ok, remote} ->
            encrypted_target = Extunnel.Crypto.encrypt(key, 
              :erlang.term_to_binary(target))
            :ok = :gen_tcp.send(remote, encrypted_target)
            case body do
              <<>> ->
                :ok
              _ ->
                :ok = :gen_tcp.send(remote, Extunnel.Crypto.encrypt(key, body))
            end
            :ok = transport.send(socket, response)
            {:ok, client(state, remote: remote)}
          {:error, reason} ->
            {:error, reason}
        end
      {:error, reason} ->
        {:error, reason}
      :more ->
        case byte_size(buffer) === 0 do
          true ->
            :ok = transport.send(socket, <<5,0>>)
          false ->
            :ok
        end
        {:ok, client(state, buffer: data1)}
    end
  end

  def request(data, client(key: key, remote: remote) = state) do
    ok = :gen_tcp.send(remote, Extunnel.Crypto.encrypt(key, data))
    {ok, state}
  end

  def find_target(<<5 :: size(8), n :: size(8), _methods :: binary-size(n)-unit(8),
      5 :: size(8), _cmd :: size(8), _rsv :: size(8), 
      aType :: size(8), rest :: binary >>) do
    case split_socket5_data(aType, rest) do
      {:ok, target, body} ->
        response = <<5, 0, 0, 1, <<0, 0, 0, 0>> :: binary, 0 :: size 16>>
        {:ok, target, body, response}
      {:error, reason} ->
        {:error, reason}
      :more ->
        :more
    end
  end

  def find_target(<<5 :: size(8), _rest :: binary>>), do: :more
  def find_target(_), do: {:error, :invalid_data}

  def split_socket5_data(1, <<address :: binary-size(4), port :: 16, body :: binary>>) do
    target = {:erlang.list_to_tuple(:erlang.binary_to_list(address)), port}
    {:ok, target, body}
  end

  def split_socket5_data(1, _) do
    :more
  end

  def split_socket5_data(3, <<len :: size(8), domain :: binary-size(len), port :: size(16), body :: binary>>) do
    target = {:erlang.list_to_tuple(:erlang.binary_to_list(domain)), port}
    {:ok, target, body}
  end

  def split_socket5_data(4, <<address :: binary-size(16), port :: 16, body :: binary >>) do
    target = {:erlang.list_to_tuple(:erlang.binary_to_list(address)), port}
    {:ok, target, body}
  end

  def split_socket5_data(4, _), do: :more
  def split_socket5_data(_,_), do: {:error, :invalid_data}
end
