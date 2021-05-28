-- Patryk Rygiel, 250080

with Graph; use Graph;

package Simulation is

    type ItemArray is array(Integer range <>, Integer range <>) of Integer;
    type IntArray is array (Integer range <>) of Integer;
    
    procedure run(graphEdges : Edges; n, k, tts, delay_limit : Integer);

end Simulation;