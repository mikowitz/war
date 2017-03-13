defmodule GameTest do
  use ExUnit.Case, async: false

  @tag :distributed
  test "running the game for a quick win" do
    IO.puts "QUICK WIN >>"
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
    IO.puts "<< QUICK WIN"
  end

  @tag :distributed
  test "running the game with a war" do
    IO.puts "ONE WAR >>"
    test_deck = [
      {"2", "S"}, {"2", "H"},
      {"5", "C"}, {"A", "S"}, {"4", "D"},
      {"3", "D"}, {"6", "D"}, {"K", "C"},
      {"J", "S"}, {"4", "C"}
    ] |> Enum.reverse
    game = Game.new(test_deck)
    michael = Player.new("Michael")
    lauren = Player.new("Lauren")

    Player.join(michael, game)
    :timer.sleep(50)
    Player.join(lauren, game)
    :timer.sleep(50)

    Player.give_card(michael, game)
    :timer.sleep(50)
    Player.give_card(lauren, game)
    :timer.sleep(50)

    Player.give_cards_for_war(michael, game)
    :timer.sleep(50)
    Player.give_cards_for_war(lauren, game)
    :timer.sleep(50)
    IO.puts "<< ONE WAR"
  end

  test "running the game with two wars" do
    IO.puts "RUNNING A GAME WITH TWO WARS >>"
    test_deck = [
      {"2", "S"}, {"2", "H"},
      {"5", "C"}, {"A", "S"}, {"4", "D"},
      {"3", "D"}, {"6", "D"}, {"K", "C"},
      {"J", "S"}, {"J", "C"},
      {"5", "D"}, {"A", "C"}, {"4", "H"},
      {"3", "H"}, {"6", "H"}, {"K", "H"},
      {"4", "S"}, {"5", "S"}
    ] |> Enum.reverse
    game = Game.new(test_deck)
    michael = Player.new("Michael")
    lauren = Player.new("Lauren")

    Player.join(michael, game)
    :timer.sleep(50)
    Player.join(lauren, game)
    :timer.sleep(50)

    Player.give_card(michael, game)
    :timer.sleep(50)
    Player.give_card(lauren, game)
    :timer.sleep(50)

    Player.give_cards_for_war(michael, game)
    :timer.sleep(50)
    Player.give_cards_for_war(lauren, game)
    :timer.sleep(50)

    Player.give_cards_for_war(michael, game)
    :timer.sleep(50)
    Player.give_cards_for_war(lauren, game)
    :timer.sleep(50)
    IO.puts "<< RUNNING A GAME WITH TWO WARS"
  end

  test "running the game with a two-card war" do
    IO.puts "RUNNING A GAME WITH TWO WARS >>"
    test_deck = [
      {"2", "S"}, {"2", "H"},
      {"5", "C"}, {"A", "S"}, {"4", "D"},
      {"3", "D"}, {"6", "D"}, {"K", "C"},
      {"J", "S"}, {"J", "C"},
      {"5", "D"}, {"A", "C"},
      {"3", "H"}, {"6", "H"},
      {"4", "S"}, {"5", "S"}
    ] |> Enum.reverse
    game = Game.new(test_deck)
    michael = Player.new("Michael")
    lauren = Player.new("Lauren")

    Player.join(michael, game)
    :timer.sleep(50)
    Player.join(lauren, game)
    :timer.sleep(50)

    Player.give_card(michael, game)
    :timer.sleep(50)
    Player.give_card(lauren, game)
    :timer.sleep(50)

    Player.give_cards_for_war(michael, game)
    :timer.sleep(50)
    Player.give_cards_for_war(lauren, game)
    :timer.sleep(50)

    Player.give_cards_for_war(michael, game)
    :timer.sleep(50)
    Player.give_cards_for_war(lauren, game)
    :timer.sleep(50)
    IO.puts "<< RUNNING A GAME WITH TWO WARS"
  end

  @tag :distributed
  test "running the game with a one-card war" do
    IO.puts "RUNNING A GAME WITH TWO WARS >>"
    test_deck = [
      {"2", "S"}, {"2", "H"},
      {"5", "C"}, {"A", "S"}, {"4", "D"},
      {"3", "D"}, {"6", "D"}, {"K", "C"},
      {"J", "S"}, {"J", "C"},
      {"5", "D"}, {"A", "C"},
      {"4", "S"}, {"5", "S"}
    ] |> Enum.reverse
    game = Game.new(test_deck)
    michael = Player.new("Michael")
    lauren = Player.new("Lauren")

    Player.join(michael, game)
    :timer.sleep(50)
    Player.join(lauren, game)
    :timer.sleep(50)

    Player.give_card(michael, game)
    :timer.sleep(50)
    Player.give_card(lauren, game)
    :timer.sleep(50)

    Player.give_cards_for_war(michael, game)
    :timer.sleep(50)
    Player.give_cards_for_war(lauren, game)
    :timer.sleep(50)

    Player.give_cards_for_war(michael, game)
    :timer.sleep(50)
    Player.give_cards_for_war(lauren, game)
    :timer.sleep(50)
    IO.puts "<< RUNNING A GAME WITH TWO WARS"
  end
end
