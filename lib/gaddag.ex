defmodule Gaas.Gaddag do
  @moduledoc """
  This module provide the functionality of the Gaddag data structure.

  Some assumptions being made by the module is that it will store
  any word, but the pound sign '#' is reserved as a special character.
  """

  defstruct store: %Gaas.NodeStore{}, root: ""

  alias Gaas.NodeStore

  @stop "#"

  @spec new :: %Gaas.Gaddag{}
  def new do
    store = NodeStore.new()
    root = NodeStore.insert_new(store, new_node())

    %Gaas.Gaddag{store: store, root: root}
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
    case NodeStore.lookup(gaddag.store, node) do
      :error      -> {:error, "invalid grapheme"}
      {:ok, map } ->
        case Map.get(map, grapheme, nil) do
          nil -> {:error, "invalid grapheme"}
          next_node ->
            case NodeStore.lookup(gaddag.store, next_node) do
              :error -> {:incomplete, next_node}
              {:ok, next_map} ->
                case Map.get(next_map, "is_word", false) do
                  true -> {:completes_word, next_node}
                  false -> {:incomplete, next_node}
                end
            end
        end
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
    case NodeStore.lookup(gaddag.store, node) do
      :error     -> :ok # The algorithm should prevent issue so we ignore it
      {:ok, map} -> NodeStore.insert(gaddag.store, node, %{map | "is_word" => true}); :ok
    end
  end

  defp do_insert(gaddag, node, _word = [letter | letters]) do
    case NodeStore.lookup(gaddag.store, node) do
      :error -> :ok # This should never happen so we ignore it
      {:ok, map} ->
        determine_next_node(gaddag, map, letter)
        |> then(&do_insert(gaddag, &1, letters))
    end
  end

  defp do_lookup(gaddag, node, []) do
    case NodeStore.lookup(gaddag.store, node) do
      :error -> :notfound
      {:ok, map} ->
         case Map.get(map, "is_word", false) do
          true -> :ok
          false -> :notfound
        end
    end
  end

  defp do_lookup(gaddag, node, [letter | letters]) do
    case NodeStore.lookup(gaddag.store, node) do
      :error -> :notfound
      {:ok, map} ->
        case Map.get(map, letter) do
          nil -> :notfound
          next_node -> do_lookup(gaddag, next_node, letters)
        end
    end
  end

  defp determine_next_node(gaddag, map, letter) do
    case Map.has_key?(map, letter) do
      true -> Map.get(map, letter)
      false -> create_new_node(gaddag)
    end
  end

  defp create_new_node(gaddag) do
    NodeStore.insert_new(gaddag.store, new_node())
  end

  defp new_node() do
    %{"is_word" => false}
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
