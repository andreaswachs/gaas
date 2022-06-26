defmodule Gaas.Gaddag do
  @moduledoc """
  This module provide the functionality of the Gaddag data structure.

  Some assumptions being made by the module is that it will store
  any word, but the pound sign '#' is reserved as a special character.


  This module creates Gaddags by help of the Erlang Term Storage (ETS).
  The Gaddag structures stored sort of like adjacency lists, which some
  important differences.

  The adjacency list likeness stems from the fact that each node in the Gaddag
  is a key-value pair stored in the ETS, where the key is a (hopefully) unique
  key and the value is a map with keys of letters going to the next nodes if
  defined, and the key "is_word" which defaults to false.
  """

  defstruct table: nil, root: ""
  @stop "#"

  @spec new :: %Gaas.Gaddag{root: binary, table: :ets.tid()}
  def new do
    table_name = new_id() |> String.to_atom()
    root = new_id()
    table = :ets.new(table_name, [:set, :public]) # I'm not sure public is right but lets see
    :ets.insert(table, {root, new_node()})

    %Gaas.Gaddag{table: table, root: root}
  end

  @spec insert(%Gaas.Gaddag{}, String.t()) :: :ok | {:error, String.t()}
  def insert(gaddag, word) do
    case is_valid_word?(word) do
      true -> insert_and_validate(gaddag, word)
      false -> {:error, "invalid word"}
    end
  end

  @spec lookup(%Gaas.Gaddag{}, String.t()) :: :ok | :notfound
  def lookup(gaddag, word) do
    word_prepped =
      (word |> String.graphemes() |> Enum.reverse()) \
      ++ [@stop]
    do_lookup(gaddag, gaddag.root, word_prepped)
  end

  @spec step(%Gaas.Gaddag{}, String.t(), String.t()) :: {:completes_word | :incomplete | :error, String.t()}
  def step(gaddag, node, grapheme) do
    case :ets.lookup(gaddag.table, node) do
      [{_, map}] ->
        case Map.get(map, grapheme, nil) do
          nil -> {:error, "invalid grapheme"}
          next_node ->
            case :ets.lookup(gaddag.table, next_node) do
              [{_, next_map}] ->
                case Map.get(next_map, "is_word", false) do
                  true -> {:completes_word, next_node}
                  false -> {:incomplete, next_node}
                end
              [] -> {:incomplete, next_node} # not sure about this
            end
        end
      [] -> {:error, "invalid node"}
    end
  end

  #
  # Private
  #

  defp insert_and_validate(gaddag, word) do
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

  defp do_insert(gaddag, node, []) do
    case :ets.lookup(gaddag.table, node) do
      [{_, map}] ->
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
    case :ets.lookup(gaddag.table, node) do
      [{_, map}] ->
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

  defp is_valid_word?(nil), do: false
  defp is_valid_word?(word) do
    Unicode.alphabetic?(word)
  end

  defp validate_results(:ok), do: true
  defp validate_results(_), do: false
  defp validate_results_inverse(result), do: not(validate_results(result))
end
