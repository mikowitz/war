defmodule Game do
  use GenStateMachine

  defmodule State do
    defstruct deck: nil, players: []
  end

  def new do
    {:ok, game} = GenStateMachine.start_link(__MODULE__, [])
    game
  end

  def init(_) do
    IO.puts "Starting a new game"
    {:ok, :waiting_for_players, %Game.State{}, [{:next_event, :internal, :enter}]}
  end

  def handle_event(:internal, :enter, :waiting_for_players, state) do
    IO.puts "players needed: #{2 - length(state.players)}"
    :keep_state_and_data
  end

  def handle_event(:cast, {:player_joined, player}, :waiting_for_players, state) do
    case length(state.players) do
      1 ->
        IO.puts "#{Player.name(player)} has joined the game"
        new_players = [player|state.players] |> Enum.reverse
        {:next_state, :ready, %{state | players: new_players}, [{:next_event, :internal, :enter}]}
      0 ->
        IO.puts "#{Player.name(player)} has joined the game"
        {:keep_state, %{state | players: [player]}, [{:next_event, :internal, :enter}]}
      _ ->
        {:stop, "Shouldn't have gotten here"}
    end
  end

  def handle_event(:internal, :enter, :ready, state) do
    IO.puts "Ready to go with #{state.players |> player_names |> Enum.join(", ")}"
    :keep_state_and_data
  end

  defp player_names(players) do
    players
    |> Enum.map(&Player.name/1)
  end
end
