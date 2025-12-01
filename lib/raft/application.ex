defmodule Raft.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children =
      if length(System.argv()) == 0 do
        [{Raft.Node, [:leader, nil]}]
      else
        node_name = Enum.at(System.argv(), 0)
        [{Raft.Node, [:follower, node_name]}]
      end

    opts = [strategy: :one_for_one, name: Raft.Supervisor]
    IO.puts("Starting up raft")
    Supervisor.start_link(children, opts)
  end
end
