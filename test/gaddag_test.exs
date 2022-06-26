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

  @tag :gaddag
  describe "inserting 20k words" do
    setup do
      gaddag = Gaddag.new()

      File.stream!("data/English20kWords.txt")
      |> Enum.map(&String.trim/1)
      |> Enum.each(fn word ->
            Gaddag.insert(gaddag, word)
        end)

      %{gaddag: gaddag}
    end

    test "can look up all 20k words again", %{gaddag: gaddag} do
      File.stream!("data/English20kWords.txt")
      |> Enum.each(fn word ->
            sanitized_word = String.trim(word)
            assert :ok = Gaddag.lookup(gaddag, sanitized_word)
          end)
    end
  end
end
