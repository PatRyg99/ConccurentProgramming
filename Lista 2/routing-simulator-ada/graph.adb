-- Patryk Rygiel, 250080

with ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Discrete_Random;

package body Graph is

    function Generate(n, d : Integer) return Edges is
        num_edges : Integer;

    begin
        num_edges := n + d - 1;

        declare 
            graphEdges : Edges(0..num_edges-1);
            
            -- Random number generator
            type randRange is new Integer range 0..n-1;
            package Rand_Int is new Ada.Numerics.Discrete_Random(randRange);
            use Rand_Int;

            gen : Generator;

            v : Integer;
            u : Integer;
            temp : Integer;

            iter : Integer := n-1;
            exists: boolean;

        begin

            -- Generating mandatory edges
            for i in 0 .. n-2 loop
                graphEdges(i).v := i;
                graphEdges(i).u := i + 1;
            end loop;

            -- Generating additional edges
            while iter < num_edges loop

                -- Generating edge vertices
                reset(gen);
                v := Integer'Value(randRange'Image(random(gen)));
                
                reset(gen);
                u := Integer'Value(randRange'Image(random(gen)));

                -- If both edges the same then skip
                if v /= u then

                    -- Swap vertices to be in ascending order
                    if v > u then
                        temp := v;
                        v := u;
                        u := temp;
                    end if;

                    -- Checking if edge already exists
                    exists := False;
                    for i in 0 .. iter-1 loop
                        if graphEdges(i).v = v and graphEdges(i).u = u then
                            exists := true;
                            exit;
                        end if;
                    end loop;

                    -- If no such edge yet - add it
                    if exists = False then
                        graphEdges(iter).v := v;
                        graphEdges(iter).u := u;

                        iter := iter + 1; 
                    end if;

                end if;
            end loop;

            -- Printing list of generated edges
            put_line("");
            put_line("--------------------------------------");
	        put_line("GENERATED GRAPH");
            put_line("");
	        put_line("|V| =" & Integer'Image(n));
	        put_line("|E| =" & Integer'Image(num_edges) & " (with d =" & Integer'Image(d) & ")");

            put_line("");
	        put_line("Edges: ");

            for i in 0 .. num_edges-1 loop
               put_line("- (" & Integer'Image(graphEdges(i).v) & "," & Integer'Image(graphEdges(i).u) & " )");
            end loop;
            
            return graphEdges;
        end;
    end Generate;

end Graph;
