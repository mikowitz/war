defmodule Deck do
  @suits ~w( C D H S )
  @ranks ~w( 2 3 4 5 6 7 8 9 T J Q K A )

  @type rank :: String.t
  @type suit :: String.t
  @type card :: {rank, suit}
  @type t :: list(card)

  def new do
    for s <- @suits, r <- @ranks do
      {r, s}
    end |> Enum.shuffle
  end

  def deal(deck, num_players) do
    hands = Enum.map(1..num_players, fn _ -> [] end)
    deal_card(deck, hands)
  end

  defp deal_card([], hands), do: hands
  defp deal_card([card|cards], [hand|hands]) do
    deal_card(cards, hands ++ [[card|hand]])
  end
end
