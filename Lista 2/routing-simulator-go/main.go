// Patryk Rygiel, 250080

package main

import (
	"os"
	"routing-simulator-go/graph"
	"routing-simulator-go/routing_table"
	"routing-simulator-go/simulation"
	"strconv"
)

func main() {
	var n, d, max_hosts, wait_limit, simulation_time int

	n, _ = strconv.Atoi(os.Args[1])
	d, _ = strconv.Atoi(os.Args[2])
	max_hosts, _ = strconv.Atoi(os.Args[3])
	wait_limit, _ = strconv.Atoi(os.Args[4])
	simulation_time, _ = strconv.Atoi(os.Args[5])

	graph := graph.GenerateGraph(n, d, max_hosts)
	routing_table.InitRoutingTable(graph)

	simulation.RunSimulation(graph, wait_limit, simulation_time)
}
