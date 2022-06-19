defmodule GaasTest do
  use ExUnit.Case
  doctest Gaas

  test "greets the world" do
    assert Gaas.hello() == :world
  end
end
