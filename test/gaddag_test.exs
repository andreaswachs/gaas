defmodule Gaas.GaddagTest do
  use ExUnit.Case

  alias Gaas.Gaddag


  @tag :gaddag
  describe "insert word \"bob\"" do
    setup do
      gaddag = Gaddag.new()
      Gaddag.insert(gaddag, "bob")

      %{gaddag: gaddag}
    end

    test "can lookup word \"bob\"", %{gaddag: gaddag} do
      assert :ok == Gaddag.lookup(gaddag, "bob")
    end

    test "does not lookup word \"bob \"", %{gaddag: gaddag} do
      assert :notfound == Gaddag.lookup(gaddag, "bob ")
    end

    test "does not lookup word \"bobb\"", %{gaddag: gaddag} do
      assert :notfound == Gaddag.lookup(gaddag, "bobb")
    end

    test "test", %{gaddag: gaddag} do
      assert :ok = Gaddag.lookup(gaddag, "b#ob")
    end
  end


  @tag :gaddag
  describe "will not accept bad input when" do
    setup do
      gaddag = Gaddag.new()

      %{gaddag: gaddag}
    end

    test "inserting nil", %{gaddag: gaddag} do
      assert {:error, _} = Gaddag.insert(gaddag, nil)
    end

    test "inserting empty string", %{gaddag: gaddag} do
      assert {:error, _} = Gaddag.insert(gaddag, "")
    end

    test "inserting string only with whitepace", %{gaddag: gaddag} do
      assert {:error, _} = Gaddag.insert(gaddag, " ")
    end

  end
end
