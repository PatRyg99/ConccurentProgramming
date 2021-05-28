-- Patryk Rygiel, 250080

with Graph; use Graph;

package Simulation is

    -- Routing table vertex object
    type RoutingTableVertex is record
        nexthop : Integer;
        cost : Integer;
        changed : Integer;
    end record;

    type RoutingTableArray is array (Integer range <>, Integer range <>) of RoutingTableVertex;
    type RoutingTableType is array (Integer range <>) of RoutingTableVertex;

    type IntArrayType is array (Integer range <>) of Integer;
    
    procedure run(graphEdges : Edges; n, max_hosts, wait_limit, simulation_time : Integer);

end Simulation;