// Patryk Rygiel, 250080

package simulation

import (
	"fmt"
	"network-simulator-go/structs"
	"network-simulator-go/threads"
)

func PrintSetup(k int, ttl int, delay_limit int) {
	fmt.Println("\n--------------------------------------")
	fmt.Printf("SIMULATION PARAMETERS\n\n")
	fmt.Println("Number of packages: ", k)
	fmt.Println("TTL (time to live): ", ttl)
	fmt.Println("Delay limit (ms): ", delay_limit)
}

func PrintStart() {
	fmt.Println("\n--------------------------------------")
	fmt.Printf("SIMULATION HAS BEEN STARTED\n\n")
}

func PrintResult(graph []structs.Vertex, packages []structs.Package, simulation_result string) {
	fmt.Println("\n--------------------------------------")
	fmt.Printf("SIMULATION HAS ENDED\n\n")
	fmt.Printf(simulation_result)

	fmt.Println("\n\nVertexes: ")
	for _, vertex := range graph {
		fmt.Println("Vertex", vertex.Id, "was visited by packages: ", vertex.Packages)
	}

	fmt.Println("\nPackages: ")
	for _, pack := range packages {
		fmt.Println("Package", pack.Id, "visited vertexes: ", pack.Vertexes)
	}
	fmt.Println("\n--------------------------------------")
}

func RunSimulation(graph []structs.Vertex, k int, ttl int, delay_limit int) {

	// Print simulation setup parameters
	PrintSetup(k, ttl, delay_limit)

	// Generate packages
	packages := func(k int) []structs.Package {
		packages := make([]structs.Package, k)

		for i := 0; i < k; i++ {
			packages[i].Id = i
			packages[i].Ttl = ttl
		}

		return packages
	}(k)

	// Create channel for each edge
	for vid := 0; vid < len(graph); vid++ {
		for _, uid := range graph[vid].Adj {

			// Create channel and
			channel := structs.Channel{Chan: make(chan *structs.Package)}
			v := &graph[vid]
			u := &graph[uid]

			// Add channels to vertices
			v.Outchans = append(v.Outchans, channel)
			u.Inchans = append(u.Inchans, channel)
		}
	}

	// Setup printing thread
	print_channel := make(chan string)
	go threads.Printer(print_channel)

	// Setup discard and poacher channel
	discard_channel := make(chan *structs.Discard)
	poacher_channel := make(chan bool)

	// Setup poacher
	go threads.Poacher(poacher_channel, delay_limit)

	// Setup sender
	source_channel := structs.Channel{Chan: make(chan *structs.Package)}
	outlet_channel := structs.Channel{Chan: make(chan *structs.Package)}
	go threads.Sender(&graph[0], delay_limit, source_channel, packages)

	// Setup stations
	for i := 0; i < len(graph); i++ {

		if i == len(graph)-1 {
			v := &graph[i]
			v.Outchans = append(v.Outchans, outlet_channel)

		} else if i == 0 {
			v := &graph[i]
			v.Inchans = append(v.Inchans, source_channel)
		}

		go threads.Station(&graph[i], delay_limit, graph[i].Inchans, graph[i].Outchans, discard_channel, poacher_channel, print_channel)
	}

	// Setup receiver
	done := make(chan string)
	go threads.Receiver(&graph[1], delay_limit, k, outlet_channel, discard_channel, done, print_channel)

	PrintStart()
	simulation_result := <-done

	// Print simulation result
	PrintResult(graph, packages, simulation_result)
}
