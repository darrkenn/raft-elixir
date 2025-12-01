# Raft-Elixir

A Raft algorithm implementation in elixir.

# Start a node as a leader
```elixir
elixir --name node1@127.0.0.1 -S mix run --no-halt
```

# Start a node as a follower 
```elixir
elixir --name node2@127.0.0.1 -S mix run --no-halt -- node1@127.0.0.1
```

