defmodule Gaas.Gaddag.TreeTest do
  use ExUnit.Case

  alias Gaas.Gaddag.Tree

  test "can insert word \"bob\"" do
    res = Tree.new() |> Tree.insert("bob")
    assert res == :ok
  end

  test "can insert and lookup \"bob\"" do
    tree = Tree.new()
    Tree.insert(tree, "bob")
    res = Tree.lookup(tree, "bob")

    assert res == :ok
  end

end
