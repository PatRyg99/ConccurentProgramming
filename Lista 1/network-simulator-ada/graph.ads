-- Patryk Rygiel, 250080

package Graph is

    -- Types for edge representation
    type Edge is record
        src  : Integer;
        dest : Integer;
    end record;

    type Edges is array (Integer range <>) of Edge; 

    function Generate(n, d, b : Integer) return Edges;
    
end Graph;