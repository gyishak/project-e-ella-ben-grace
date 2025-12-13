defmodule EnvModule do
    @type env :: %{atom() => EValModule.eVal}
end

defmodule ECoreModule do
    @type eCore ::
        {:numCE, number()} |
        {:biopCE, atom(), t(), t()} |
        {:boolCE, boolean()} |
        {:condCE, t(), t(), t()} |
        {:varCE, atom()} |
        {:letCE, atom(), t(), t()} |
        {:lamCE, list(atom()), t()} |
        {:appCE, t(), list(t())}

    @type t :: eCore()
end

defmodule EValModule do
    @type eVal ::
        {:numV, number()}|
        {:boolV, boolean()}|
        {:closV, list(atom()), ECoreModule.t(), EnvModule.env()}
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
            {:biopCE, op, l, r} -> 
                cond do
                    op == :"&&" -> 
                        lv = interp(l, env)
                        case lv do
                            {:boolV, ln} -> 
                                if ln do
                                    rv = interp(r, env)
                                    case rv do 
                                        {:boolV, rn} -> {:boolV, ln and rn}
                                        _ -> raise "expected operand to be a boolean"
                                    end
                                else
                                    {:boolV, false}
                                end
                            _ -> raise "expected operand to be a boolean"
                        end
                    op == :"||" -> 
                        lv = interp(l, env)
                        case lv do
                            {:boolV, ln} -> 
                                if ln do
                                    {:boolV, true}
                                else
                                    rv = interp(r, env)
                                    case rv do 
                                        {:boolV, rn} -> {:boolV, ln or rn}
                                        _ -> raise "expected operand to be a boolean"
                                    end
                                end
                            _ -> raise "expected operand to be a boolean"
                        end
                    true -> 
                        BiopModule.biop(op, interp(l, env), interp(r, env))
                end
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

defmodule Elixhami.Syntax do
    def num(n), do: {:numCE, n}
    def bool(b), do: {:boolCE, b}
    def var(name), do: {:varCE, name}

    def add(l, r), do: {:biopCE, :+, l, r}
    def sub(l, r), do: {:biopCE, :-, l, r}
    def mult(l, r), do: {:biopCE, :*, l, r}
    def div(l, r), do: {:biopCE, :/, l, r}
    def eq(l, r), do: {:biopCE, :"=?", l, r}
    def gt(l, r), do: {:biopCE, :">?", l, r}
    def lt(l, r), do: {:biopCE, :"<?", l, r}

    def if(test, test_then, test_else), do: {:condCE, test, test_then, test_else}
    def let(var, value, body), do: {:letCE, var, value, body}
    
    def lam(vars, body), do: {:lamCE, vars, body}
    def app(fun, args), do: {:appCE, fun, args}
end




ExUnit.start()

defmodule ECoreTest do
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

defmodule EValTest do
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


defmodule InterpTest do
  use ExUnit.Case
  @mt_env %{}
  ## simple evaluation tests
  test "cond test must be boolean" do
    assert_raise RuntimeError, "expected test to be a boolean", fn ->
      InterpModule.interp({:condCE, {:numCE, 7}, {:numCE, 3}, {:numCE, 4}}, @mt_env)
    end
  end
  test "simple biop eval" do
    assert InterpModule.interp({:biopCE, :"+", {:numCE, 2}, {:numCE, 3}}, @mt_env) ==
             {:numV, 5}
  end
  test "cond false branch" do
    assert InterpModule.interp(
             {:condCE, {:boolCE, false}, {:numCE, 42}, {:numCE, 99}},
             @mt_env
           ) == {:numV, 99}
  end
  ## && and || error tests
  test "&& lhs not boolean" do
    assert_raise RuntimeError, "expected operand to be a boolean", fn ->
      InterpModule.interp(
        {:biopCE, :"&&", {:numCE, 7}, {:boolCE, false}},
        @mt_env
      )
    end
  end
  test "&& rhs not boolean" do
    assert_raise RuntimeError, "expected operand to be a boolean", fn ->
      InterpModule.interp(
        {:biopCE, :"&&", {:boolCE, true}, {:numCE, 7}},
        @mt_env
      )
    end
  end
  test "|| lhs not boolean" do
    assert_raise RuntimeError, "expected operand to be a boolean", fn ->
      InterpModule.interp(
        {:biopCE, :"||", {:numCE, 7}, {:boolCE, true}},
        @mt_env
      )
    end
  end
  test "|| rhs not boolean" do
    assert_raise RuntimeError, "expected operand to be a boolean", fn ->
      InterpModule.interp(
        {:biopCE, :"||", {:boolCE, false}, {:numCE, 7}},
        @mt_env
      )
    end
  end
  ## lambda and function tests
  test "lambda evaluates to closure" do
    assert InterpModule.interp({:lamCE, [:x], {:numCE, 42}}, @mt_env) ==
             {:closV, [:x], {:numCE, 42}, @mt_env}
  end
  test "function application" do
    assert InterpModule.interp(
             {
               :appCE,
               {:lamCE, [:x], {:biopCE, :"+", {:varCE, :x}, {:numCE, 1}}},
               [{:numCE, 5}]
             },
             @mt_env
           ) == {:numV, 6}
  end
  ## function application error tests
  test "non-function application" do
    assert_raise RuntimeError, "expected a function", fn ->
      InterpModule.interp(
        {:appCE, {:numCE, 5}, [{:numCE, 3}]},
        @mt_env
      )
    end
  end
  test "arity mismatch" do
    assert_raise RuntimeError, fn ->
      InterpModule.interp(
        {
          :appCE,
          {:lamCE, [:x, :y], {:biopCE, :"+", {:varCE, :x}, {:varCE, :y}}},
          [{:numCE, 5}]
        },
        @mt_env
      )
    end
  end
  ## && interp tests
  test "&& true true" do
    assert InterpModule.interp(
             {:biopCE, :"&&", {:boolCE, true}, {:boolCE, true}},
             @mt_env
           ) == {:boolV, true}
  end
  test "&& true false" do
    assert InterpModule.interp(
             {:biopCE, :"&&", {:boolCE, true}, {:boolCE, false}},
             @mt_env
           ) == {:boolV, false}
  end
  ## short circuit tests for &&
  test "&& short-circuits division by zero" do
    assert InterpModule.interp(
             {:biopCE, :"&&", {:boolCE, false},
              {:biopCE, :"/", {:numCE, 1}, {:numCE, 0}}},
             @mt_env
           ) == {:boolV, false}
  end
  test "&& short-circuits unbound variable" do
    assert InterpModule.interp(
             {:biopCE, :"&&", {:boolCE, false},
              {:varCE, :"this-should-not-fail"}},
             @mt_env
           ) == {:boolV, false}
  end
  test "&& short-circuits invalid application" do
    assert InterpModule.interp(
             {:biopCE, :"&&", {:boolCE, false},
              {:appCE, {:numCE, 5}, [{:numCE, 3}]}},
             @mt_env
           ) == {:boolV, false}
  end
  ## short circuit tests for ||
  test "|| short-circuits division by zero" do
    assert InterpModule.interp(
             {:biopCE, :"||", {:boolCE, true},
              {:biopCE, :"/", {:numCE, 1}, {:numCE, 0}}},
             @mt_env
           ) == {:boolV, true}
  end
  test "|| short-circuits unbound variable" do
    assert InterpModule.interp(
             {:biopCE, :"||", {:boolCE, true},
              {:varCE, :"this-shoulld-not-fail"}},
             @mt_env
           ) == {:boolV, true}
  end
  test "|| short-circuits invalid application" do
    assert InterpModule.interp(
             {:biopCE, :"||", {:boolCE, true},
              {:appCE, {:numCE, 5}, [{:numCE, 3}]}},
             @mt_env
           ) == {:boolV, true}
  end
  ## || interp tests
  test "|| false false" do
    assert InterpModule.interp(
             {:biopCE, :"||", {:boolCE, false}, {:boolCE, false}},
             @mt_env
           ) == {:boolV, false}
  end
  test "|| false true" do
    assert InterpModule.interp(
             {:biopCE, :"||", {:boolCE, false}, {:boolCE, true}},
             @mt_env
           ) == {:boolV, true}
  end
end