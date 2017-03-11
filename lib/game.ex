defmodule Game do
  use GenStateMachine

  defmodule State do
    defstruct deck: nil, players: [],
      turn: 1, hands: %{}
  end

  def new(deck \\ Deck.new) do
    {:ok, game} = GenStateMachine.start_link(__MODULE__, deck)
    game
  end

  def init(deck) do
    IO.puts "Starting a new game"
    {:ok, :waiting_for_players, %Game.State{deck: deck}, [{:next_event, :internal, :enter}]}
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
    new_state = deal_cards(state)
    {:next_state, :turn, new_state, [{:next_event, :internal, :enter}]}
  end

  def handle_event(:internal, :enter, :turn, state) do
    IO.puts "Turn: #{state.turn}"
    IO.puts "Current decks:"
    Enum.each(state.hands, fn {player, hand} ->
      IO.puts "  #{Player.name(player)} -> #{length(hand)}"
    end)
    Enum.players.each(state.players, fn player ->
      Player.request_card(player)
    end)
    :keep_state_and_data
  end

  def handle_event(_, {:player_joined, player}, _, state) do
    IO.puts "Sorry, #{Player.name(player)}! This game is full!"
    :keep_state_and_data
  end

  defp player_names(players) do
    players
    |> Enum.map(&Player.name/1)
  end

  defp deal_cards(state) do
    hands = state.players
    |> Enum.zip(Deck.deal(state.deck, 2))
    |> Enum.into(Map.new)
    %{state | hands: hands}
  end
end
