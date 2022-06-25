defmodule Gaas.Gaddag.Tree do
  @moduledoc """
  This module (will) provide the functionality of the
  Gaddag data structure.

  Some assumptions being made by the module is that it will store
  any word, but the pound sign '#' is reserved as a special character.
  """

  defstruct table: nil, root: ""
  @stop "#"

  @spec new :: %Gaas.Gaddag.Tree{root: binary, table: :ets.tid()}
  def new do
    table_name = new_id() |> String.to_atom()
    root = new_id()
    table = :ets.new(table_name, [:set, :private])
    :ets.insert(table, {root, new_node()})

    %Gaas.Gaddag.Tree{table: table, root: root}
  end

  @spec insert(%Gaas.Gaddag.Tree{}, String.t()) :: :ok | {:error, String.t()}
  def insert(gaddag, word) do
    letters = String.graphemes(word)
    results =
      for permuted_letters <- permutate_letters(letters) do
        do_insert(gaddag, gaddag.root, permuted_letters)
      end

    case Enum.any?(results, &validate_results/1) do
      true -> :ok
      false -> Enum.find(results, {:error, "error missing, "}, &validate_results_inverse/1)
    end
  end

  defp validate_results(:ok), do: true
  defp validate_results(_), do: false

  defp validate_results_inverse(result), do: validate_results(result) |> not()

  @spec lookup(%Gaas.Gaddag.Tree{}, String.t()) :: :ok | :notfound
  def lookup(gaddag, word) do
    do_lookup(gaddag, gaddag.root, String.graphemes(word))
  end

  #
  # Private
  #

  defp do_insert(gaddag, node, []) do
    case :ets.lookup(gaddag.table, node) do
      [{^node, map}] ->
        :ets.insert(gaddag.table, {node, %{map | "is_word" => true}})
        :ok
      [] -> {:error, "Disconnected Gaddag. Last letter to insert reached."}
    end
  end

  defp do_insert(gaddag, node, _word = [letter | letters]) do
    case :ets.lookup(gaddag.table, node) do
      [{_, map}] ->
        next_node = determine_next_node(gaddag, map, letter)
        new_map = Map.put(map, letter, next_node)
        :ets.insert(gaddag.table, {node, new_map})
        do_insert(gaddag, next_node, letters)
      [] -> {:error, "The Gaddag has been disconnected from itself!"}
    end
  end

  defp do_lookup(gaddag, node, []) do
    # if is_word is true on this node, return :ok, else {:}
    case :ets.lookup(gaddag.table, node) do
      [{^node, map}] ->
        case Map.get(map, "is_word", false) do
          true -> :ok
          false -> :notfound
        end
      _ -> :notfound
    end
  end

  defp do_lookup(gaddag, node, [letter | letters]) do
    case :ets.lookup(gaddag.table, node) do
      [{_, map}] ->
        case Map.get(map, letter) do
          nil -> :notfound
          next_node -> do_lookup(gaddag, next_node, letters)
        end
      _ -> :notfound
    end
  end

  defp determine_next_node(gaddag, map, letter) do
    case Map.has_key?(map, letter) do
      true -> Map.get(map, letter)
      false -> create_new_node(gaddag)
    end
  end

  defp create_new_node(gaddag) do
    id = new_id()
    :ets.insert(gaddag.table, {id, new_node()})
    id
  end

  defp new_node() do
    %{"is_word" => false}
  end

  defp new_id do
    :crypto.strong_rand_bytes(20) |> Base.encode64()
  end

  defp permutate_letters(letters) do
    for i <- Enum.to_list(1..Kernel.length(letters)) do
      List.insert_at(letters, i, @stop)
      |> then(combine_letters(i))
    end
  end

  defp combine_letters(i) do
    fn letters ->
      before_stop = Enum.take(letters, i) |> Enum.reverse()
      after_stop = Enum.drop(letters, i)
      before_stop ++ after_stop
    end
  end
end
