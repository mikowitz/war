defmodule Game do
  use GenStateMachine

  defmodule PlayerState do
    defstruct hand: [], played_cards: [],
      winner: false,
      times_played: 0
  end

  defmodule State do
    defstruct deck: nil, players: [],
      turn: 1, player_states: %{},
      winner: nil
  end

  def new(deck \\ Deck.new) do
    {:ok, game} = GenStateMachine.start_link(__MODULE__, deck)
    game
  end

  def init(deck) do
    IO.puts "Starting a new game"
    {:ok, :waiting_for_players, %Game.State{deck: deck}, [{:next_event, :internal, :enter}]}
  end

  def play_card(game, player) do
    GenStateMachine.cast(game, {:play_card, player})
  end

  def play_war(game, player) do
    GenStateMachine.cast(game, {:play_war, player})
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
        player_states = new_players |> Enum.map(fn player -> {player, %PlayerState{}} end) |> Enum.into(Map.new)
        {:next_state, :ready, %{state | players: new_players, player_states: player_states}, [{:next_event, :internal, :enter}]}
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
    IO.puts "Current hand count:"
    Enum.each(state.player_states, fn {player, %{hand: hand}} ->
      IO.puts "  #{Player.name(player)} -> #{length(hand)}"
    end)
    Enum.each(state.players, fn player ->
      Player.request_card(player)
    end)
    :keep_state_and_data
  end

  def handle_event(:cast, {:play_card, player}, :turn, state) do
    IO.puts "#{Player.name(player)} is playing a card..."
    handle_play_card(player, state)
  end

  def handle_event(_, {:player_joined, player}, _, state) do
    IO.puts "Sorry, #{Player.name(player)}! This game is full!"
    :keep_state_and_data
  end

  def handle_event(:internal, :enter, :judge_turn, state) do
    IO.puts "Let's see what's going on here..."
    Enum.each(state.player_states, fn {player, %{played_cards: played_cards}} ->
      card = List.first(played_cards)
      IO.puts "#{Player.name(player)} played #{inspect card}"
    end)
    all_played_cards = Enum.map(state.player_states, fn {_, %{played_cards: played_cards}} ->
      played_cards
    end)
    case is_tie(all_played_cards) do
      true ->
        IO.puts "WAR TIME!"
        {:next_state, :war, state, [{:next_event, :internal, :enter}]}
      false ->
        {winner, _} = state.player_states
        |> Enum.max_by(fn {_, %{played_cards: [card|_]}} -> Deck.value(card) end)
        IO.puts "#{Player.name(winner)} wins!"

        won_cards = state.player_states
        |> Enum.map(fn {_, %{played_cards: cards}} -> cards end)
        |> List.flatten |> Enum.shuffle

        new_player_states = state.player_states
        |> Enum.map(fn {player, player_state} ->
          new_state = %{player_state | played_cards: []}
          new_state = case player == winner do
            true -> %{new_state | hand: new_state.hand ++ won_cards}
            false -> new_state
          end
          {player, new_state}
        end) |> Enum.into(Map.new)
        new_state = %{state | player_states: new_player_states}
        {:next_state, :check_for_game_end, new_state, [{:next_event, :internal, :enter}]}
    end
  end

  def handle_event(:internal, :enter, :war, state) do
    Enum.each(state.players, fn player ->
      Player.request_war(player)
    end)
    :keep_state_and_data
  end

  def handle_event(:cast, {:play_war, player}, :war, state) do
    IO.puts "#{Player.name(player)} is playing cards for war..."
    handle_play_cards_for_war(player, state)
  end

  def handle_event(:internal, :enter, :check_for_game_end, state) do
    case Enum.find(state.player_states, fn {_, %{hand: hand}} -> length(hand) == length(state.deck) end) do
      {player, _} ->
        {:next_state, :game_over, %{state | winner: player }, [{:next_event, :internal, :enter}]}
      x ->
        {:next_state, :turn, %{state | turn: state.turn + 1}, [{:next_event, :internal, :enter}]}
    end
  end

  def handle_event(:internal, :enter, :game_over, state) do
    IO.puts "#{Player.name(state.winner)} won the game!"
    {:stop, :normal}
  end

  def handle_event(_, event, current_state, _) do
    IO.puts "received #{inspect event} in #{inspect current_state}"
    {:keep_state_and_data, [:postpone]}
  end

  defp player_names(players) do
    players
    |> Enum.map(&Player.name/1)
  end

  defp deal_cards(state) do
    new_player_states = state.players
    |> Enum.zip(Deck.deal(state.deck, 2))
    |> Enum.into(Map.new)
    |> Enum.reduce(state.player_states, fn({player, cards}, player_states) ->
      current_player_state = player_states[player]
      new_player_state = %{current_player_state | hand: cards}
      Map.put(player_states, player, new_player_state)
    end)
    %{state | player_states: new_player_states}
  end

  defp handle_play_card(player, state) do
    player_state = state.player_states[player]
    case player_state.played_cards do
      n when n in [nil, []] ->
        [card|hand] = player_state.hand
        new_player_state = %{player_state | played_cards: [card], hand: hand, times_played: player_state.times_played + 1}
        new_state = %{state | player_states: Map.put(state.player_states, player, new_player_state)}
        case Enum.map(new_state.player_states, fn {_, %{times_played: times_played}} -> times_played end) |> Enum.uniq |> length do
          1 ->
            {:next_state, :judge_turn, new_state, [{:next_event, :internal, :enter}]}
          _ ->
            {:keep_state, new_state}
        end
      _ ->
        :keep_state_and_data
    end
  end

  defp update_state_for_war(player, new_played_cards, new_hand, state) do
    player_state = state.player_states[player]
    new_player_state = %{player_state | hand: new_hand,
     played_cards: new_played_cards ++ player_state.played_cards,
     times_played: player_state.times_played + 1}

    new_player_states = Map.put(state.player_states, player, new_player_state)
    new_state = %{state | player_states: new_player_states}
    case Enum.map(new_state.player_states, fn {_, %{times_played: times_played}} -> times_played end) |> Enum.uniq |> length do
      1 ->
        {:next_state, :judge_turn, new_state, [{:next_event, :internal, :enter}]}
      _ ->
        {:keep_state, new_state}
    end
  end

  defp handle_play_cards_for_war(player, state) do
    player_state = state.player_states[player]
    case player_state.hand do
      [a,b,c,d|hand] ->
        update_state_for_war(player, [d,c,b,a], hand, state)
      [a,b,c] ->
        update_state_for_war(player, [c,b,a], [], state)
      [a, b] ->
        update_state_for_war(player, [b,a], [], state)
      [a] ->
        update_state_for_war(player, [a], [], state)
      [] ->
        IO.puts "#{Player.name(player)} can't play any cards."
        winner = Enum.find(state.players, &(&1 != player))
        {:next_state, :game_over, %{state | winner: winner}, [{:next_event, :internal, :enter}]}
      _ ->
        :keep_state_and_data
    end
  end

  defp is_tie(played_cards) do
    [{r1, _}, {r2, _}] = Enum.map(played_cards, fn cards -> List.first(cards) end) |> List.flatten
    r1 == r2
  end

end
