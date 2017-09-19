# Extunnel

**A fast & lightweight tunnel proxy**

## Illustrate

```
+------------+            +--------------+          
| local app  |  <=======> | proxy client | <#######
+------------+            +--------------+        #
                                                  #
                                                  #
                                                  # encrypted data
                                                  #
                                                  #
+-------------+            +--------------+       #
| target host |  <=======> | proxy server |  <#####
+-------------+            +--------------+         
```


## Installation

1. Install Erlang & Elixir.
2. `git clone https://github.com/sllt/extunnel.git`

## Usage

1. `cd extunnel`
2. `mix deps.get`
3. `mv config/config.exs.example config/config.exs`
4. run `iex -S mix` and enter `Extunnel.start_client` or `Extunnel.start_server`


