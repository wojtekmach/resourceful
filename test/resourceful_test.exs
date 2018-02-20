defmodule ResourcefulTest do
  use ExUnit.Case
  doctest Resourceful

  test "greets the world" do
    assert Resourceful.hello() == :world
  end
end
