defmodule Gaas.NodeStoreTest do
  use ExUnit.Case

  alias Gaas.NodeStore

  setup do
    store = NodeStore.new()

    %{store: store}
  end

  test "can insert a value", %{store: store} do
    NodeStore.insert(store, "foo", "bar")

    res = NodeStore.lookup(store, "foo")

    assert res == {:ok, "bar"}
  end

  test "can not lookup key not inserted", %{store: store} do
    res = NodeStore.lookup(store, "foo")

    assert res == :error
  end

  test "can insert into new node", %{store: store} do
    id = NodeStore.insert_new(store, "bar")

    res = NodeStore.lookup(store, id)

    assert res == {:ok, "bar"}
  end



end
