defmodule Game do
  use GenStateMachine

  defmodule State do
    defstruct deck: nil, players: [],
      turn: 1, hands: %{},
      played_cards: %{},
      winner: nil,
      times_played: %{}
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
        times_played = Enum.map(new_players, fn p -> {p, 0} end) |> Enum.into(Map.new)
        {:next_state, :ready, %{state | players: new_players, times_played: times_played}, [{:next_event, :internal, :enter}]}
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
    Enum.each(state.hands, fn {player, hand} ->
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

  def is_tie(played_cards) do
    [{r1, _}, {r2, _}] = Enum.map(played_cards, fn {_, cards} -> List.first(cards) end) |> List.flatten
    r1 == r2
  end

  def handle_event(:internal, :enter, :judge_turn, state) do
    IO.puts "Let's see what's going on here..."
    Enum.each(state.players, fn player ->
      card = Map.get(state.played_cards, player) |> List.first
      IO.puts "#{Player.name(player)} played #{inspect card}"
    end)
    case is_tie(state.played_cards) do
      true ->
        IO.puts "WAR TIME!"
        {:next_state, :war, state, [{:next_event, :internal, :enter}]}
      false ->
        {winner, _} = state.played_cards
        |> Enum.max_by(fn {_, [card|_]} -> Deck.value(card) end)
        IO.puts "#{Player.name(winner)} wins!"

        won_cards = state.played_cards
        |> Enum.map(fn {_, cards} -> cards end)
        |> List.flatten |> Enum.shuffle
        new_hands = Map.put(state.hands, winner, state.hands[winner] ++ won_cards)
        new_state = %{state | hands: new_hands, played_cards: %{}}
        {:next_state, :check_for_game_end, new_state, [{:next_event, :internal, :enter}]}
    end
  end

  def handle_event(:internal, :enter, :judge_war, state) do
    IO.puts "Let's see what's going on here..."
    Enum.each(state.players, fn player ->
      card = Map.get(state.played_cards, player) |> List.first
      IO.puts "#{Player.name(player)} played #{inspect card}"
    end)
    case is_tie(state.played_cards) do
      true ->
        IO.puts "WAR TIME!"
        {:next_state, :war, state, [{:next_event, :internal, :enter}]}
      false ->
        {winner, _} = state.played_cards
        |> Enum.max_by(fn {_, [card|_]} -> Deck.value(card) end)
        IO.puts "#{Player.name(winner)} wins!"

        won_cards = state.played_cards
        |> Enum.map(fn {_, cards} -> cards end)
        |> List.flatten |> Enum.shuffle
        new_hands = Map.put(state.hands, winner, state.hands[winner] ++ won_cards)
        new_state = %{state | hands: new_hands, played_cards: %{}}
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
    case Enum.find(state.hands, fn {_, cards} -> length(cards) == length(state.deck) end) do
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
    hands = state.players
    |> Enum.zip(Deck.deal(state.deck, 2))
    |> Enum.into(Map.new)
    %{state | hands: hands}
  end

  defp handle_play_card(player, state) do
    case Map.get(state.played_cards, player) do
      n when n in [nil, []] ->
        [card|hand] = Map.get(state.hands, player)
        new_played_cards = Map.put(state.played_cards, player, [card])
        new_hands = Map.put(state.hands, player, hand)
        new_played = Map.put(state.times_played, player, state.times_played[player] + 1)
        new_state = %{state | played_cards: new_played_cards, hands: new_hands, times_played: new_played}
        case Enum.map(new_played, fn {_, p} -> p end) |> Enum.uniq |> length == 1 do
          true ->
            {:next_state, :judge_turn, new_state, [{:next_event, :internal, :enter}]}
          false ->
            {:keep_state, new_state}
        end
      _ ->
        :keep_state_and_data
    end
  end

  defp handle_play_cards_for_war(player, state) do
    case Map.get(state.hands, player) do
      [a,b,c,d|hand] ->
        new_played_cards = Map.put(state.played_cards, player, [d,c,b,a|state.played_cards[player]])
        new_hands = Map.put(state.hands, player, hand)
        new_played = Map.put(state.times_played, player, state.times_played[player] + 1)
        new_state = %{state | played_cards: new_played_cards, hands: new_hands, times_played: new_played}
        case Enum.map(new_played, fn {_, p} -> p end) |> Enum.uniq |> length == 1 do
          true ->
            {:next_state, :judge_war, new_state, [{:next_event, :internal, :enter}]}
          false ->
            {:keep_state, new_state}
        end
      [a,b,c] ->
        new_played_cards = Map.put(state.played_cards, player, [c,b,a|state.played_cards[player]])
        new_hands = Map.put(state.hands, player, [])
        new_played = Map.put(state.times_played, player, state.times_played[player] + 1)
        new_state = %{state | played_cards: new_played_cards, hands: new_hands, times_played: new_played}
        case Enum.map(new_played, fn {_, p} -> p end) |> Enum.uniq |> length == 1 do
          true ->
            {:next_state, :judge_war, new_state, [{:next_event, :internal, :enter}]}
          false ->
            {:keep_state, new_state}
        end
      [a, b] ->
        new_played_cards = Map.put(state.played_cards, player, [b,a|state.played_cards[player]])
        new_hands = Map.put(state.hands, player, [])
        new_played = Map.put(state.times_played, player, state.times_played[player] + 1)
        new_state = %{state | played_cards: new_played_cards, hands: new_hands, times_played: new_played}
        case Enum.map(new_played, fn {_, p} -> p end) |> Enum.uniq |> length == 1 do
          true ->
            {:next_state, :judge_war, new_state, [{:next_event, :internal, :enter}]}
          false ->
            {:keep_state, new_state}
        end
      [a] ->
        new_played_cards = Map.put(state.played_cards, player, [a|state.played_cards[player]])
        new_hands = Map.put(state.hands, player, [])
        new_played = Map.put(state.times_played, player, state.times_played[player] + 1)
        new_state = %{state | played_cards: new_played_cards, hands: new_hands, times_played: new_played}
        case Enum.map(new_played, fn {_, p} -> p end) |> Enum.uniq |> length == 1 do
          true ->
            {:next_state, :judge_war, new_state, [{:next_event, :internal, :enter}]}
          false ->
            {:keep_state, new_state}
        end
      [] ->
        IO.puts "#{Player.name(player)} can't play any cards."
        winner = Enum.find(state.players, &(&1 != player))
        {:next_state, :game_over, %{state | winner: winner}, [{:next_event, :internal, :enter}]}
      _ ->
        :keep_state_and_data
    end
  end
end
