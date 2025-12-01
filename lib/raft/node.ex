defmodule Raft.Node do
  use GenServer

  # @heartbeat 100
  # @election_min 150
  # @election_max 300

  defstruct log: [
              :index,
              :term,
              :command
            ]

  def start_link([role, node_name]) do
    GenServer.start_link(__MODULE__, %{role: role, node_name: node_name}, name: __MODULE__)
  end

  def init(%{role: role, node_name: node_name}) do
    state =
      if role == :leader do
        IO.puts("Starting node as a leader")

        %{
          role: :leader,
          voted_for: nil,
          peers: Node.list(),
          log: [],
          term_number: 1,
          votes: nil
        }
      else
        IO.puts("Starting node as a follower")
        Node.connect(:"#{node_name}")

        %{
          role: :follower,
          voted_for: nil,
          peers: Node.list(),
          log: [],
          term_number: nil,
          votes: nil
        }
      end

    Process.send_after(self(), :refresh_peers, 5_000)
    {:ok, state}
  end

  def handle_info(:refresh_peers, state) do
    peers = Node.list()
    new_state = %{state | peers: peers}
    Process.send_after(self(), :refresh_peers, 5_000)
    {:noreply, new_state}
  end
end
