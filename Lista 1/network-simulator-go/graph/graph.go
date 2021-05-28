// Patryk Rygiel, 250080

package graph

import (
	"fmt"
	"math/rand"
	"network-simulator-go/structs"
	"time"
)

func GenerateGraph(n int, d int, b int) []structs.Vertex {

	// Graph is represented as an adjecency list
	graph := make([]structs.Vertex, n)

	// Setting seed for edge randomisation
	rand.Seed(time.Now().UnixNano())

	// Initlizing vertices and adding mandatory edges
	for i := 0; i < n; i++ {
		graph[i].Id = i

		if i != n-1 {
			graph[i].Adj = append(graph[i].Adj, i+1)
		}
	}

	// Adding forward shortcuts
	temp_d := d
	for temp_d > 0 {
		start := rand.Intn(n - 2)
		end := rand.Intn(n-1-start) + start + 1

		exists := false

		// Check if edge exists
		for i := 0; i < n; i++ {

			vertex := &graph[i]

			// Check for start vertex
			if vertex.Id == start {
				for _, uid := range vertex.Adj {

					// If exists - break and generate new one
					if uid == end {
						exists = true
						break
					}
				}

				if !exists {
					vertex.Adj = append(vertex.Adj, end)
					temp_d--
				}
			}
		}
	}

	// Adding backward shortcuts
	temp_b := b
	for temp_b > 0 {
		start := rand.Intn(n-1) + 1
		end := rand.Intn(start)

		exists := false

		// Check if edge exists
		for i := 0; i < n; i++ {

			vertex := &graph[i]

			// Check for start vertex
			if vertex.Id == start {
				for _, uid := range vertex.Adj {

					// If exists - break and generate new one
					if uid == end {
						exists = true
						break
					}
				}

				if !exists {
					vertex.Adj = append(vertex.Adj, end)
					temp_b--
				}
			}
		}
	}

	PrintGraph(graph, n, d, b)
	return graph
}

func PrintGraph(graph []structs.Vertex, n int, d int, b int) {
	fmt.Println("\n--------------------------------------")
	fmt.Printf("GENERATED DIRECTED ACYCLIC GRAPH\n\n")
	fmt.Println("|V| =", n)
	fmt.Printf("|E| = %d (with d = %d, b = %d)\n\n", n-1+d+b, d, b)

	fmt.Println("Adjecency list: ")
	for _, vertex := range graph {
		var tag = fmt.Sprintf("Vertex %d: ", vertex.Id)
		fmt.Println(tag, vertex.Adj)
	}
}
