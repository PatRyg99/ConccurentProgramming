// Patryk Rygiel, 250080

package graph

import (
	"fmt"
	"math/rand"
	"routing-simulator-go/structs"
	"time"
)

func GenerateGraph(n int, d int, max_hosts int) []structs.Vertex {

	// Graph is represented as an adjecency list
	graph := make([]structs.Vertex, n)

	// Setting seed for edge randomisation
	rand.Seed(time.Now().UnixNano())

	// Initlizing vertices and adding mandatory edges (in both ways)
	for i := 0; i < n; i++ {
		graph[i].Id = i
		graph[i].Hosts = rand.Intn(max_hosts) + 1

		if i != n-1 {
			graph[i].Adj = append(graph[i].Adj, i+1)
		}

		if i != 0 {
			graph[i].Adj = append(graph[i].Adj, i-1)
		}
	}

	// Adding shortcuts
	temp_d := d
	for temp_d > 0 {
		v1 := rand.Intn(n)
		v2 := rand.Intn(n)

		exists := false

		if v1 != v2 {

			vertex1 := &graph[v1]
			vertex2 := &graph[v2]

			for _, uid := range vertex1.Adj {

				// If exists - break and generate new one
				if uid == v2 {
					exists = true
					break
				}
			}

			if !exists {
				vertex1.Adj = append(vertex1.Adj, v2)
				vertex2.Adj = append(vertex2.Adj, v1)
				temp_d--
			}
		}
	}

	PrintGraph(graph, n, d, max_hosts)
	return graph
}

func PrintGraph(graph []structs.Vertex, n int, d int, max_hosts int) {
	fmt.Println("\n--------------------------------------")
	fmt.Printf("GENERATED GRAPH\n\n")
	fmt.Println("|V| =", n)
	fmt.Printf("|E| = %d (with d = %d)\n", n-1+d, d)
	fmt.Printf("max_hosts = %d\n\n", max_hosts)

	fmt.Println("Adjecency list and hosts: ")
	for _, vertex := range graph {
		var tag = fmt.Sprintf("Vertex %d: ", vertex.Id)
		fmt.Println(tag, vertex.Adj, ", hosts = ", vertex.Hosts)
	}
}
