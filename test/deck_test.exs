defmodule DeckTest do
  use ExUnit.Case

  describe ".value/1" do
    test "it returns a sortable value for the card" do
      card = {"3", "S"}
      assert Deck.value(card) == {1, 3}
    end
  end
end
