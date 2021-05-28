// Patryk Rygiel, 250080

package simulation

import (
	"fmt"
	"routing-simulator-go/structs"
	"routing-simulator-go/threads"
	"time"
)

func PrintSetup(wait_limit int, simulation_time int) {
	fmt.Println("\n--------------------------------------")
	fmt.Printf("SIMULATION PARAMETERS\n\n")
	fmt.Println("Wait limit (ms): ", wait_limit)
	fmt.Println("Simulation time (s): ", simulation_time)
}

func PrintStart() {
	fmt.Println("\n--------------------------------------")
	fmt.Printf("SIMULATION HAS BEEN STARTED\n\n")
}

func PrintResult(graph []structs.Vertex) {
	fmt.Println("\n--------------------------------------")
	fmt.Printf("SIMULATION HAS ENDED\n")

	for i := 0; i < len(graph); i++ {
		fmt.Println("\nVertex ", i, " routing table:")

		for j := 0; j < len(graph[i].RoutingTable); j++ {

			if j != i {
				text := fmt.Sprint(
					"\tR[", j, "] = (cost: ",
					graph[i].RoutingTable[j].Cost, " nexthop: ",
					graph[i].RoutingTable[j].Nexthop, ")",
				)

				fmt.Println(text)
			}

		}
	}

	fmt.Println("")
}

func RunSimulation(graph []structs.Vertex, wait_limit int, simulation_time int) {

	// Print simulation setup parameters
	PrintSetup(wait_limit, simulation_time)
	PrintStart()

	hosts := []structs.Address{}

	// Create channel for each edge
	for vid := 0; vid < len(graph); vid++ {

		for j := 0; j < graph[vid].Hosts; j++ {
			hosts = append(hosts, structs.Address{RouterId: vid, HostId: j})
		}

		for _, uid := range graph[vid].Adj {

			v := &graph[vid]
			u := &graph[uid]

			// Create routing channel
			channel := make(chan *structs.Package)

			// Create forwarder channel
			forwarder_in_channel := make(chan *structs.HostPackage)
			forwarder_out_channel := structs.ForwarderOutChannel{DestId: u.Id, Channel: forwarder_in_channel}

			// Add channels to vertices
			v.OutChannels = append(v.OutChannels, channel)
			u.InChannels = append(u.InChannels, channel)

			v.OutForwarderChannels = append(v.OutForwarderChannels, forwarder_out_channel)
			u.InForwarderChannels = append(u.InForwarderChannels, forwarder_in_channel)
		}
	}

	// Setup printing thread with timeout check
	done := make(chan bool)
	print_channel := make(chan string)
	go threads.Printer(print_channel, simulation_time, done)

	// Setup vertexes' threads
	for i := 0; i < len(graph); i++ {

		sender_channel := make(chan structs.ReadOp)
		reader_channel := make(chan structs.WriteOp)
		next_hop_channel := make(chan structs.NextHopOp)

		queue_channel := make(chan structs.QueueOp)
		dequeue_channel := make(chan structs.DequeueOp)

		// Set stateful goroutines
		go threads.Queue(&graph[i], queue_channel, dequeue_channel)
		go threads.State(&graph[i], sender_channel, reader_channel, next_hop_channel, print_channel)

		// Set hosts threads per vertex
		host_sender_channels := []chan *structs.HostPackage{}
		host_receiver_channels := []chan *structs.HostPackage{}

		for j := 0; j < graph[i].Hosts; j++ {
			address := structs.Address{RouterId: i, HostId: j}
			host_sender_channels = append(host_sender_channels, make(chan *structs.HostPackage))
			host_receiver_channels = append(host_receiver_channels, make(chan *structs.HostPackage))

			go threads.Host(address, hosts, host_sender_channels[j], host_receiver_channels[j], wait_limit, print_channel)
		}

		// Append router hosts to in/out channels of forwarder
		graph[i].InForwarderChannels = append(graph[i].InForwarderChannels, host_sender_channels...)

		// Set vertex forwarder threads
		go threads.ForwarderReceiver(&graph[i], graph[i].InForwarderChannels, queue_channel, print_channel)
		go threads.ForwarderSender(&graph[i], graph[i].OutForwarderChannels, host_receiver_channels, dequeue_channel, next_hop_channel, print_channel)

		// Set vertex routing threads
		go threads.Receiver(&graph[i], graph[i].InChannels, reader_channel)
		go threads.Sender(&graph[i], wait_limit, graph[i].OutChannels, sender_channel)

	}

	// Wait for done message
	<-done
	time.Sleep(time.Duration(float64(wait_limit) * float64(time.Millisecond)))

	// Print simulation result
	PrintResult(graph)
}
