-- Patryk Rygiel, 250080
with ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Discrete_Random;
with Graph; use Graph;
with Tasks; use Tasks;

package body Simulation is

    function GetNeighbours(id, n : Integer; graphEdges : Edges) return IntArrayType is
         neighbours : IntArrayType(0..n-1) := (others => 0);
    begin
         for i in graphEdges'Range loop

            if graphEdges(i).v = id then
               neighbours(graphEdges(i).u) := 1;

            elsif graphEdges(i).u = id then
               neighbours(graphEdges(i).v) := 1;

            end if;
         end loop;

         return neighbours;
    end GetNeighbours;

    function GenerateHosts(n, max_hosts : Integer) return IntArrayType is
         hosts : IntArrayType(0..n-1) := (others => 0);

         type randRange is new Integer range 1..max_hosts;
         package Rand_Int is new Ada.Numerics.Discrete_Random(randRange);
         use Rand_Int;

         gen : Generator;
    begin

         for i in 0..n-1 loop
            hosts(i) := Integer'Value(randRange'Image(random(gen)));   
         end loop;

         return hosts;
    end GenerateHosts;


    procedure run(graphEdges : Edges; n, max_hosts, wait_limit, simulation_time : Integer) is

        -- Lists of custom length
        subtype Vertex is Integer range 0 .. n-1;

        -- Routing tables
        routingTables : RoutingTableArray(Vertex, Vertex);

        -- Neighbours
        neighbours : IntArrayType(Vertex);
        
        -- Hosts
        hosts : IntArrayType(Vertex);

    begin
        -- Init hosts and print
        hosts := GenerateHosts(n, max_hosts);
        
        put_line("");
        put_line("max_hosts =" & Integer'Image(max_hosts));
        put_line("");
	     put_line("Hosts: ");

        for i in 0 .. n-1 loop
           put_line("Router" & Integer'Image(i) & ":" & Integer'Image(hosts(i)));
        end loop;

        -- Printing setup
        put_line("");
        put_line("--------------------------------------");
	     put_line("SIMULATION PARAMETERS");
        put_line("");
	     put_line("Wait limit (ms):" & Integer'Image(wait_limit));
        put_line("Simulation time (s):" & Integer'Image(simulation_time));

        -- Initializing routing tables
         for i in 0 .. n-1 loop
               neighbours := GetNeighbours(i, n, graphEdges);
            for j in 0 .. n-1 loop

               -- Known neighbours
               if neighbours(j) = 1 then
                  routingTables(i, j).nexthop := j;
                  routingTables(i, j).cost := 1;
               
               -- No relation known
               elsif i < j then
                  routingTables(i, j).nexthop := i + 1;
                  routingTables(i, j).cost := j - i;
               else
                  routingTables(i, j).nexthop := i - 1;
                  routingTables(i, j).cost := i - j;

               end if;

               routingTables(i, j).changed := 1;

            end loop;
         end loop;

        -- Printing simulation start
        put_line("");
        put_line("--------------------------------------");
	     put_line("SIMULATION HAS BEEN STARTED");
        put_line("");

        Tasks.Launch(n, wait_limit, simulation_time, graphEdges, hosts, routingTables);

        -- Printing simulation end
        put_line("");
        put_line("--------------------------------------");
	     put_line("SIMULATION HAS ENDED");
        put_line("");
        
        -- Printing routing tables
        for i in 0 .. n-1 loop
           put_line("Vertex" & Integer'Image(i) & " routing table:");

           for j in 0 .. n-1 loop

               if j /= i then
                  put("R[" & Integer'Image(j) & " ] = (");
                  put(" cost:" & Integer'Image(routingTables(i, j).cost));
                  put(" nexthop:" & Integer'Image(routingTables(i, j).nexthop));
                  put_line(" )");
               end if;

           end loop;

           put_line("");
        end loop;

        put_line("");

    end run;
end Simulation;