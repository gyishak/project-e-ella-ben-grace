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

