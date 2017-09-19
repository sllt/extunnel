defmodule Extunnel.Client do

  require Record
  Record.defrecord :client, [key: :undefined, ref: :undefined, socket: :undefined,
    transport: :undefined, ok: :undefined, closed: :undefined, error: :undefined,
    remote: :undefined, protocol: :undefined, buffer: :undefined,
    keep_alive: false]
  @type client :: record(:client, key: String.t, ref: any, socket: any, transport: atom,
    ok: any, closed: any, error: any, remote: port | :undefined, protocol: atom | :undefined,
    buffer: byte, keep_alive: boolean)
  
end
