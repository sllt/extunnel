# Extunnel

**A fast & lightweight tunnel proxy**

## Illustrate

```
+------------+                        +--------------+          
| local app  |  <--socks5 protocol--> | proxy client | <-------
+------------+                        +--------------+        |
                                                              |
                                                              |
                                                        encrypted data
                                                              |
                                                              |
+-------------+                       +--------------+        |
| target host |  <------------------> | proxy server |   <-----
+-------------+                       +--------------+         
```


## Usage
1. Install Erlang & Elixir.
2. `git clone https://github.com/sllt/extunnel.git`
3. `cd extunnel`
4. `mix deps.get`
5. `mv config/config.exs.example config/config.exs`

Explanation of the key:

| Name | Explanation |
| --- | --- |
| server_addr | server address |
| server_port | server port |
| client_port | client port |
| key | key to encrypt data(must be 16 bytes) |

6. run `bash server.sh` to start server and run `bash client.sh` to start client.

