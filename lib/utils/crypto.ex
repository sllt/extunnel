defmodule Extunnel.Crypto do
  @datalength 16
  @iv <<"^de$@#56*sxdfrtg">>

  def encrypt(key, binary) do
    binary_length = byte_size(binary)
    r = rem(binary_length + 4,@datalength)
    addition_length = @datalength - r

    final_binary = <<binary_length :: big-integer-size(32), binary :: binary, 0 :: size(addition_length)-unit(8)>>
    :crypto.block_encrypt(:aes_cbc128, key, @iv, final_binary)
  end

  def decrypt(key, binary) do
    data = :crypto.block_decrypt(:aes_cbc128, key, @iv, binary)
    try do
      <<length :: big-integer-size(32), real_data :: binary-size(length), _rest :: binary>> = data
      {:ok, real_data}
    catch
      value -> 
        {:error, value}
    end
  end


end