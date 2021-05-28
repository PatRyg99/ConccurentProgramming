// Patryk Rygiel, 250080

package routing_table

import (
	"routing-simulator-go/structs"
)

func InitRoutingTable(graph []structs.Vertex) {

	for i := 0; i < len(graph); i++ {
		vertex := &graph[i]

		for j := 0; j < len(graph); j++ {

			// Init values when is neighbour
			nexthop := j
			cost := 1
			changed := true

			// If not neighbour change init values
			if !VertexInAdj(j, vertex) {
				if i < j {
					cost = j - i
					nexthop = i + 1

				} else {
					cost = i - j
					nexthop = i - 1
				}
			}

			// Append new routing table vertex
			vertex.RoutingTable = append(
				vertex.RoutingTable,
				structs.RoutingTableVertex{
					Nexthop: nexthop,
					Cost:    cost,
					Changed: changed,
				},
			)
		}
	}
}

func VertexInAdj(uid int, vertex *structs.Vertex) bool {

	// Check whether given uid is neighbour of vertex
	for i := 0; i < len(vertex.Adj); i++ {
		if uid == vertex.Adj[i] {
			return true
		}
	}

	return false
}
