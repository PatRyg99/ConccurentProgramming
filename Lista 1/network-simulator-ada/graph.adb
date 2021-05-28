-- Patryk Rygiel, 250080

with ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Discrete_Random;

package body Graph is

    function Generate(n, d, b : Integer) return Edges is
        num_edges : Integer;

    begin
        num_edges := n + d + b - 1;

        declare 
            graphEdges : Edges(0..num_edges-1);
            
            -- Random number generator
            type randRange is new Integer range 0..n-1;
            package Rand_Int is new Ada.Numerics.Discrete_Random(randRange);
            use Rand_Int;

            gen : Generator;

            src : Integer;
            dest : Integer;
            temp : Integer;

            iter : Integer := n-1;
            exists: boolean;

        begin

            -- Generating mandatory edges
            for i in 0 .. n-2 loop
                graphEdges(i).src := i;
                graphEdges(i).dest := i + 1;
            end loop;

            -- Generating forward edges
            while iter < n + d - 1 loop

                -- Generating edge source
                reset(gen);
                src := Integer'Value(randRange'Image(random(gen)));
                
                -- Generating edge destination
                reset(gen);
                dest := Integer'Value(randRange'Image(random(gen)));

                -- If both edges the same then skip
                if src /= dest then
                    if src > dest then
                        temp := src;
                        src := dest;
                        dest := temp;
                    end if;

                    -- Checking if edge already exists
                    exists := False;
                    for i in 0 .. iter-1 loop
                        if graphEdges(i).src = src and graphEdges(i).dest = dest then
                            exists := true;
                            exit;
                        end if;
                    end loop;

                    -- If no such edge yet - add it
                    if exists = False then
                        graphEdges(iter).src := src;
                        graphEdges(iter).dest := dest;

                        iter := iter + 1; 
                    end if;

                end if;
            end loop;

            -- Generating backward edges
            while iter < num_edges loop

                -- Generating edge source
                reset(gen);
                src := Integer'Value(randRange'Image(random(gen)));
                
                -- Generating edge destination
                reset(gen);
                dest := Integer'Value(randRange'Image(random(gen)));

                -- If both edges the same then skip
                if src /= dest then
                    if src < dest then
                        temp := src;
                        src := dest;
                        dest := temp;
                    end if;

                    -- Checking if edge already exists
                    exists := False;
                    for i in 0 .. iter-1 loop
                        if graphEdges(i).src = src and graphEdges(i).dest = dest then
                            exists := true;
                            exit;
                        end if;
                    end loop;

                    -- If no such edge yet - add it
                    if exists = False then
                        graphEdges(iter).src := src;
                        graphEdges(iter).dest := dest;

                        iter := iter + 1; 
                    end if;

                end if;
            end loop;

            -- Printing list of generated edges
            put_line("");
            put_line("--------------------------------------");
	        put_line("GENERATED DIRECTED ACYCLIC GRAPH");
            put_line("");
	        put_line("|V| =" & Integer'Image(n));
	        put_line("|E| =" & Integer'Image(num_edges) & " (with d =" & Integer'Image(d) & ", b =" & Integer'Image(b) & ")");

            put_line("");
	        put_line("Edges: ");

            for i in 0 .. num_edges-1 loop
               put_line("- (" & Integer'Image(graphEdges(i).src) & "," & Integer'Image(graphEdges(i).dest) & " )");
            end loop;
            
            return graphEdges;
        end;
    end Generate;

end Graph;
