defmodule GameTest do
  use ExUnit.Case

  test ".new/0 returns a PID" do
    assert is_pid(Game.new)
  end
end
