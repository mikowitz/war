defmodule Deck do
  @moduledoc """
  Models a standard 52 card deck of cards
  """

  @suits ~w( C D H S )
  @ranks ~w( 2 3 4 5 6 7 8 9 T J Q K A )

  @type rank :: String.t
  @type suit :: String.t
  @type card :: {rank, suit}
  @type t :: list(card)

  @doc """
  Returns a new shuffled deck
  """
  @spec new :: Deck.t
  def new do
    new_deck = for s <- @suits, r <- @ranks do
      {r, s}
    end
    new_deck |> Enum.shuffle
  end

  @doc """
  Deals a deck out between `num_players` players.
  """
  @spec deal(Deck.t, integer) :: list(Deck.t)
  def deal(deck, num_players) do
    hands = Enum.map(1..num_players, fn _ -> [] end)
    deal_card(deck, hands)
  end

  @spec rank_value(card) :: integer
  def rank_value({r, _}) do
    Enum.find_index(@ranks, &(&1 == r))
  end

  @spec suit_value(card) :: integer
  def suit_value({_, s}) do
    Enum.find_index(@suits, &(&1 == s))
  end

  @spec value(card) :: {integer, integer}
  def value(card) do
    {rank_value(card), suit_value(card)}
  end

  defp deal_card([], hands), do: hands
  defp deal_card([card|cards], [hand|hands]) do
    deal_card(cards, hands ++ [[card|hand]])
  end
end
