defmodule EnvModule do
    @type env :: %{atom() => BValModule.bVal}
end

defmodule BCoreModule do
    @type bcore ::
        {:numCE, number()} |
        {:biopCE, atom(), t(), t()} |
        {:boolCE, boolean()} |
        {:condCE, t(), t(), t()} |
        {:varCE, atom()} |
        {:letCE, atom(), t(), t()} |
        {:lamCE, list(atom()), t()} |
        {:appCE, t(), list(t())}

    @type t :: bcore()
end

defmodule BValModule do
    @type bVal ::
        {:numV, number()}|
        {:boolV, boolean()}|
        {:closV, list(atom()), BCoreModule.bCore, EnvModule.env}
end


ExUnit.start()

defmodule BCoreTest do
  use ExUnit.Case

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
