defmodule Game do
  use GenStateMachine

  defmodule State do
    defstruct deck: nil
  end

  def new do
    {:ok, game} = GenStateMachine.start_link(__MODULE__, [])
    game
  end

  def init(_) do
    {:ok, :waiting_for_players, %Game.State{}, [{:next_event, :internal, :enter}]}
  end

  def handle_event(:internal, :enter, :waiting_for_players, state) do
    IO.puts "Waiting for players to join"
    :keep_state_and_data
  end
end
