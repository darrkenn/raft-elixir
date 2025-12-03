defmodule Raft.Kv do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def new_entry({key, value}, state) do
    new_state =
      if !Map.has_key?(state, key) do
        Map.put(state, key, value)
      end

    new_state
  end

  def new_entry({key, value}), do: GenServer.call(__MODULE__, {:new_entry, key, value})
  def retrieve_entry(key), do: GenServer.call(__MODULE__, {:retrieve_entry, key})

  def handle_call({:new_entry, key, value}, _, state) do
    new_state = if !Map.has_key?(state, key), do: Map.put(state, key, value), else: state
    {:reply, :ok, new_state}
  end

  def handle_call({:retrieve_entry, key}, _from, state) do
    value = if Map.has_key?(state, key), do: Map.get(state, key, ""), else: :entry_not_found

    {:reply, value, state}
  end
end
