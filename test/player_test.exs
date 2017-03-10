defmodule PlayerTest do
  use ExUnit.Case

  test "creation returns a pid" do
    assert is_pid(Player.new("Michael"))
  end

  test ".name/1 returns the player's name" do
    player = Player.new("Michael")
    assert Player.name(player) == "Michael"
  end
end
