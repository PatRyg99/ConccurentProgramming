-- Patryk Rygiel, 250080

package Graph is

    -- Types for edge representation
    type Edge is record
        v  : Integer;
        u : Integer;
    end record;

    type Edges is array (Integer range <>) of Edge; 

    function Generate(n, d : Integer) return Edges;
    
end Graph;