-- Patryk Rygiel, 250080

with ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;

with Graph; use Graph;
with Simulation;

procedure Main is
    n, d, max_hosts, wait_limit, simulation_time : Integer;
begin

    n := Integer'Value(Ada.Command_Line.argument(1));
    d := Integer'Value(Ada.Command_Line.argument(2));
    max_hosts := Integer'Value(Ada.Command_Line.argument(3));
    wait_limit := Integer'Value(Ada.Command_Line.argument(4));
    simulation_time := Integer'Value(Ada.Command_Line.argument(5));

    declare
       graphEdges : Edges := Generate(n, d);
    begin
       Simulation.run(graphEdges, n, max_hosts, wait_limit, simulation_time);
    end;
   
end Main;