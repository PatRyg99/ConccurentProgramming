// Patryk Rygiel, 250080

package main

import (
	"network-simulator-go/graph"
	"network-simulator-go/simulation"
	"os"
	"strconv"
)

func main() {
	var n, d, b, k, ttl, delay_limit int

	n, _ = strconv.Atoi(os.Args[1])
	d, _ = strconv.Atoi(os.Args[2])
	b, _ = strconv.Atoi(os.Args[3])
	k, _ = strconv.Atoi(os.Args[4])
	ttl, _ = strconv.Atoi(os.Args[5])
	delay_limit, _ = strconv.Atoi(os.Args[6])

	graph := graph.GenerateGraph(n, d, b)
	simulation.RunSimulation(graph, k, ttl, delay_limit)
}
