defmodule Player do
  use GenServer

  defstruct name: nil

  def new(name) do
    {:ok, player} = GenServer.start_link(__MODULE__, name)
    player
  end

  def name(player) do
    GenServer.call(player, :name)
  end

  def join(player, game) do
    GenStateMachine.cast(game, {:player_joined, player})
  end

  def init(name) do
    {:ok, %__MODULE__{name: name}}
  end

  def handle_call(:name, _from, state) do
    {:reply, state.name, state}
  end
end
