defmodule Gaas.NodeStore do
  @moduledoc """
  NodeStore is a simple key-value store implemented with ETS
  """

  defstruct table: nil


  @spec new :: %Gaas.NodeStore{}
  def new do
    # This is a little dangerous as atoms will never be gc'd
    table_name = new_id() |> String.to_atom()
    table = :ets.new(table_name, [:set, :public])

    %Gaas.NodeStore{table: table}
  end

  @spec lookup(%Gaas.NodeStore{}, String.t()) :: {:ok, any()} | :error
  def lookup(store, key) do
    case :ets.lookup(store.table, key) do
      [{_, value}] -> {:ok, value}
      _ -> :error
    end
  end

  @spec insert(%Gaas.NodeStore{}, String.t(), any()) :: :ok
  def insert(store, key, value) do
    :ets.insert(store.table, {key, value})
    :ok
  end

  @spec insert_new(%Gaas.NodeStore{}, any()) :: String.t()
  def insert_new(store, value) do
    # This function has the astronomically small risk of running forever
    id = new_id()
    case lookup(store.table, id) do
      {:ok, _} -> insert_new(store, value)
      :error   -> insert(store, id, value); id
    end
  end

  #
  # Helpers
  #

  def new_id() do
    :crypto.strong_rand_bytes(32)
    |> Base.encode64()
  end


end
