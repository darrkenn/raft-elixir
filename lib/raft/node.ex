defmodule Raft.Node do
  use GenServer

  @election_min 150
  @election_max 300

  defstruct log_entry: [
              :index,
              :term,
              :command
            ]

  def start_link([role, node_name]) do
    GenServer.start_link(__MODULE__, %{role: role, node_name: node_name}, name: __MODULE__)
  end

  def init(%{role: role, node_name: node_name}) do
    state =
      case role do
        :leader ->
          IO.puts("Starting node as a leader")

          %{
            role: :leader,
            leader: nil,
            voted_for: nil,
            peers: Node.list(),
            log: [],
            latest_log_entry: nil,
            latest_log_index: nil,
            term_number: 1,
            election_timeout: nil,
            votes: nil
          }

        :follower ->
          IO.puts("Starting node as a follower")
          IO.puts("Connecting to #{node_name}")
          Node.connect(:"#{node_name}")
          election_timeout = :rand.uniform(@election_max - @election_min + 1) + @election_min - 1

          %{
            role: :follower,
            leader: nil,
            voted_for: nil,
            peers: Node.list(),
            log: [],
            latest_log_entry: nil,
            latest_log_index: nil,
            term_number: nil,
            election_timeout: election_timeout,
            election_timer: nil,
            votes: nil
          }
      end

    case role do
      :leader ->
        Process.send_after(self(), :send_heartbeat, 100)

      :follower ->
        update_leader(node_name)
    end

    Process.send_after(self(), :refresh_peers, 5_000)
    {:ok, state}
  end

  def update_leader(node_name) do
    leader = get_leader(node_name)
    set_leader(leader)
  end

  def get_leader(node_name), do: GenServer.call({Raft.Node, :"#{node_name}"}, {:who_is_leader})
  def set_leader(leader), do: GenServer.cast(__MODULE__, {:set_leader, leader})

  def handle_info(:send_heartbeat, state) do
    if length(state.peers) >= 1 do
      Enum.each(state.peers, fn peer ->
        GenServer.cast({Raft.Node, :"#{peer}"}, {:heartbeat})
      end)
    end

    Process.send_after(self(), :send_heartbeat, 100)
    {:noreply, state}
  end

  def handle_info(:refresh_peers, state) do
    peers = Node.list()
    new_state = %{state | peers: peers}
    Process.send_after(self(), :refresh_peers, 5_000)
    {:noreply, new_state}
  end

  def handle_info(:election_timeout, state) do
    IO.puts("ELECTION STARTED")
    {:noreply, state}
  end

  def handle_cast({:heartbeat}, state) do
    IO.puts("Received heartbeat, resetting election")

    if state.election_timer do
      Process.cancel_timer(state.election_timer)
    end

    election_timer = Process.send_after(self(), :election_timeout, state.election_timeout)
    {:noreply, %{state | election_timer: election_timer}}
  end

  def handle_cast({:set_leader, leader}, state) do
    {:noreply, %{state | leader: leader}}
  end

  def handle_call({:who_is_leader}, _from, state) do
    leader =
      case state.role do
        :leader ->
          Node.self()

        :follower ->
          state.leader
      end

    {:reply, leader, state}
  end
end
