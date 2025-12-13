defmodule EnvModule do
    @type env :: %{atom() => BValModule.bVal}
end

defmodule BCoreModule do
    @type bCore ::
        {:numCE, number()} |
        {:biopCE, atom(), t(), t()} |
        {:boolCE, boolean()} |
        {:condCE, t(), t(), t()} |
        {:varCE, atom()} |
        {:letCE, atom(), t(), t()} |
        {:lamCE, list(atom()), t()} |
        {:appCE, t(), list(t())}

    @type t :: bCore()
end

defmodule BValModule do
    @type bVal ::
        {:numV, number()}|
        {:boolV, boolean()}|
        {:closV, list(atom()), BCoreModule.t(), EnvModule.env()}
end

defmodule InterpModule do
    def interp(expression, env ____) do
        case expression do
            {:numCE, n} -> {:numV, n}
            {:biopCE, op, l, r} -> {}
            {:boolCE, b} -> {:boolV, b}
            {:condCE, test, then, else} -> {}
            {:varCE, name} -> Map.fetch!(env, name)
            {:letCE, var, val, body} -> 
                value = interp(val, env)
                new_env = Map.put(env, var, value)
                interp(body, new_env)
            {:lamCE, vars, body} -> {}
            {:appCE, function, args} -> {}
        end
    end
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

defmodule BValTest do
  use ExUnit.Case

  test "numV" do
    assert {:numV, 7} ==
           {:numV, 7}
  end

  test "boolV" do
    assert {:boolV, true} ==
           {:boolV, true}
  end

  test "closV" do
    mt_env = %{}
    body =
      {:biopCE, :+,
       {:varCE, :x},
       {:varCE, :y}}

    assert {:closV, [:x, :y], body, mt_env} ==
           {:closV, [:x, :y], body, mt_env}
  end
end
