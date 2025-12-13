defmodule BCoreModule do
    @type BCore ::
        {:numCE, number()} |
        {:biopCE, atom(), BCore(), BCore()} |
        {:boolCE, boolean()} |
        {:condCE, BCore(), BCore(), BCore()} |
        {:varCE, atom()} |
        {:letCE, atom(), BCore(), BCore()} |
        {:lamCE, list(atom()), BCore()} |
        {:appCE, BCore(), list(BCore())}
end

ExUnit.start()

defmodule BCoreTest do
  use ExUnit.Case
  alias BCoreModule, as: B

  test "numCE" do
    assert {:numCE, 5} ==
           {:numCE, 5}
  end

  test "biopCE" do
    assert {:biopCE, :+, {:numCE, 2}, {:numCE, 3}} ==
           {:biopCE, :+, {:numCE, 2}, {:numCE, 3}}
  end

  test "boolCE" do
    assert {:boolCE, true} ==
           {:boolCE, true}
  end

  test "condCE" do
    assert {:condCE,
            {:boolCE, true},
            {:numCE, 1},
            {:numCE, 2}} ==
           {:condCE,
            {:boolCE, true},
            {:numCE, 1},
            {:numCE, 2}}
  end

  test "varCE" do
    assert {:varCE, :x} ==
           {:varCE, :x}
  end

  test "letCE" do
    assert {:letCE,
            :x,
            {:numCE, 1},
            {:varCE, :x}} ==
           {:letCE,
            :x,
            {:numCE, 1},
            {:varCE, :x}}
  end
end
