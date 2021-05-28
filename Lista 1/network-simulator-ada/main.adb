-- Patryk Rygiel, 250080

with ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;

with Graph; use Graph;
with Simulation;

procedure Main is
    n, d, b, k, tts, delay_limit : Integer;
begin

    n := Integer'Value(Ada.Command_Line.argument(1));
    d := Integer'Value(Ada.Command_Line.argument(2));
    b := Integer'Value(Ada.Command_Line.argument(3));
    k := Integer'Value(Ada.Command_Line.argument(4));
    tts := Integer'Value(Ada.Command_Line.argument(5));
    delay_limit := Integer'Value(Ada.Command_Line.argument(6));

    declare
       graphEdges : Edges := Generate(n, d, b);
    begin
       Simulation.run(graphEdges, n, k, tts, delay_limit);
    end;
   
end Main;