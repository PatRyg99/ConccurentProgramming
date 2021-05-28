-- Patryk Rygiel, 250080
with ada.Text_IO; use Ada.Text_IO;
with Graph; use Graph;
with Tasks; use Tasks;

package body Simulation is

    procedure run(graphEdges : Edges; n, k, tts, delay_limit : Integer) is

        -- Lists of custom length
        subtype Vertex is Integer range 0 .. n-1;
        subtype Pkg is Integer range 0 .. k-1;

        -- Packages and vertexes paths
        vertexes : ItemArray(Vertex, Pkg) := (others => (others => -1));
        packages : ItemArray(Pkg, Vertex) := (others => (others => -1));

        -- Packages state
        PackagesState : IntArray(0 .. n-1) := (others => -1);

    begin

        -- Printing setup
        put_line("");
        put_line("--------------------------------------");
	     put_line("SIMULATION PARAMETERS");
        put_line("");
	     put_line("Number of packages:" & Integer'Image(k));
        put_line("TTS (time to live):" & Integer'Image(tts));
	     put_line("Delay limit (ms):" & Integer'Image(delay_limit));

        -- Printing simulation start
        put_line("");
        put_line("--------------------------------------");
	     put_line("SIMULATION HAS BEEN STARTED");
        put_line("");

        Tasks.Launch(n, k, tts, delay_limit, graphEdges, vertexes, packages, packagesState);

        -- Printing simulation end
        put_line("");
        put_line("--------------------------------------");
	     put_line("SIMULATION HAS ENDED");
        put_line("");

        -- Printing packages' states
        put("Packages received: [");
        for i in 0 .. n-1 loop
            if packagesState(i) = 1 then
               put(Integer'Image(i) & ",");
            end if;
        end loop;
        put("]");
        put_line("");

        put("Packages discarded: [");
        for i in 0 .. n-1 loop
            if packagesState(i) = 2 then
               put(Integer'Image(i) & ",");
            end if;
        end loop;
        put("]");
        put_line("");

        put("Packages caught: [");
        for i in 0 .. n-1 loop
            if packagesState(i) = 3 then
               put(Integer'Image(i) & ",");
            end if;
        end loop;
        put("]");
        put_line("");
        put_line("");
        
        -- Printing vertexes
	     put_line("Vertexes: ");
        for i in 0 .. n-1 loop
           put("Vertex" & Integer'Image(i) & " was visited by packages: [");
           for j in 0 .. k-1 loop
              if vertexes(i, j) /= -1 then
                put(Integer'Image(vertexes(i, j)) & ",");
              end if;
           end loop;

           put("]");
           put_line("");
        end loop;

        -- Printing packages
        put_line("");
	     put_line("Packages: ");
        for i in 0 .. k-1 loop
           put("Package" & Integer'Image(i) & " visited vertexes: [");
           for j in 0 .. n-1 loop
              if packages(i, j) /= -1 then
                put(Integer'Image(packages(i, j)) & ",");
              end if;
           end loop;

           put("]");
           put_line("");
        end loop;

        put_line("");

    end run;
end Simulation;