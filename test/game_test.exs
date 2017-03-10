defmodule GameTest do
  use ExUnit.Case

  test "running the game" do
    game = Game.new
    michael = Player.new("Michael")
    lauren = Player.new("Lauren")

    Player.join(michael, game)
    :timer.sleep(50)
    Player.join(lauren, game)
    :timer.sleep(50)
  end
end
