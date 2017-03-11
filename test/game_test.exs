defmodule GameTest do
  use ExUnit.Case

  test "running the game for a quick win" do
    test_deck = [{"2", "S"}, {"3", "H"}, {"5", "C"}, {"A", "S"}]
    game = Game.new(test_deck)
    michael = Player.new("Michael")
    lauren = Player.new("Lauren")
    jeffrey = Player.new("Jeffrey")

    Player.join(michael, game)
    :timer.sleep(50)
    Player.join(lauren, game)
    :timer.sleep(50)
    Player.join(jeffrey, game)
    :timer.sleep(50)


    :timer.sleep(100)

    Player.give_card(michael, game)
    :timer.sleep(50)
    Player.give_card(lauren, game)
    :timer.sleep(50)

    Player.give_card(michael, game)
    :timer.sleep(50)
    Player.give_card(lauren, game)
    :timer.sleep(50)
  end
end
