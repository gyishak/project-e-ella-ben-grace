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

defmodule BiopModule do
  def biop(op, v1, v2) do
    case v1 do
      {:numV, x} ->
        case v2 do
          {:numV, y} ->
            cond do
              op == :+ -> {:numV, x + y}
              op == :* -> {:numV, x * y}
              op == :/ -> if y == 0 do
                  raise "div: divide by zero"
                else
                  {:numV, x / y}
                end
              op == :- -> {:numV, x - y}
              op == :"=?" -> {:boolV, x == y}
              op == :">?" -> {:boolV, x > y}
              op == :"<?" -> {:boolV, x < y}
              true ->
                raise "#{op}: unknown binary operation"
            end
          _ ->
            raise "#{op}: expected RHS to be a number"
        end
      _ ->
        raise "#{op}: expected LHS to be a number"
    end
  end
end

defmodule InterpModule do
    def interp(expression, env) do
        case expression do
            {:numCE, n} -> {:numV, n}
            {:biopCE, op, l, r} -> {}
            {:boolCE, b} -> {:boolV, b}
            {:condCE, test, test_then, test_else} -> 
                test_boolean = interp(test, env)
                if test_boolean do
                    interp(test_then, env)
                else
                    interp(test_else, env)
                end
            {:varCE, name} -> Map.fetch!(env, name)
            {:letCE, var, val, body} -> 
                value = interp(val, env)
                new_env = Map.put(env, var, value)
                interp(body, new_env)
            {:lamCE, vars, body} -> {:closV, vars, body, env}
            {:appCE, function, args} -> 
                {:closV, params, body, clos_env} = interp(function, env)
                args_values = Enum.map(args, fn(arg) -> interp(arg, env) end)
                new_env = Enum.into(Enum.zip(params, args_values), clos_env)
                interp(body, new_env)
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

defmodule BiopTest do
  use ExUnit.Case
  import BiopModule
  test "arithmetic" do
    assert biop(:+, {:numV, 2}, {:numV, 3}) == {:numV, 5}
    assert biop(:*, {:numV, 4}, {:numV, 2}) == {:numV, 8}
    assert biop(:-, {:numV, 5}, {:numV, 1}) == {:numV, 4}
    assert biop(:/, {:numV, 8}, {:numV, 2}) == {:numV, 4}
  end
  test "equality" do
    assert biop(:"=?", {:numV, 3}, {:numV, 3}) == {:boolV, true}
    assert biop(:"=?", {:numV, 3}, {:numV, 4}) == {:boolV, false}
  end
  test "greater-than" do
    assert biop(:">?", {:numV, 5}, {:numV, 3}) == {:boolV, true}
    assert biop(:">?", {:numV, 2}, {:numV, 7}) == {:boolV, false}
  end
  
  test "less-than" do
    assert biop(:"<?", {:numV, 2}, {:numV, 7}) == {:boolV, true}
    assert biop(:"<?", {:numV, 8}, {:numV, 7}) == {:boolV, false}
  end
  
  test "type and operator errors" do
    assert_raise RuntimeError, "+: expected LHS to be a number", fn ->
      biop(:+, {:boolV, true}, {:numV, 1})
    end
    assert_raise RuntimeError, "-: expected RHS to be a number", fn ->
      biop(:-, {:numV, 1}, {:boolV, false})
    end
    assert_raise RuntimeError, "div: divide by zero", fn ->
      biop(:/, {:numV, 1}, {:numV, 0})
    end
    assert_raise RuntimeError, "$: unknown binary operation", fn ->
      biop(:"$", {:numV, 2}, {:numV, 2})
    end
  end
end
