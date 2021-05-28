-- Patryk Rygiel, 250080

with Graph; use Graph;
with Simulation; use Simulation;

package Tasks is
    
    procedure Launch(
        n, wait_limit, simulation_time : Integer;
        graphEdges : Edges; 
        hosts : IntArrayType;
        routingTables : out RoutingTableArray);
    
    -- Pair, list of them to be sent as router package
    type Pair is record
        id   : Integer;
        cost : Integer;
    end record;

    type Pairs is array (Integer range <>) of Pair; 

end Tasks;