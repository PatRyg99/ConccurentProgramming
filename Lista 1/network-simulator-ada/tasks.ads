-- Patryk Rygiel, 250080

with Graph; use Graph;
with Simulation; use Simulation;

package Tasks is
    
    procedure Launch(
        n, k, tts, delay_limit : Integer;
        graphEdges : Edges; 
        vertexes, packages : out ItemArray;
        packagesState : out IntArray);
    
end Tasks;