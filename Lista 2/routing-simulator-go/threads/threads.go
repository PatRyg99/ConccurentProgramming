// Patryk Rygiel, 250080

package threads

import (
	"fmt"
	"math/rand"
	"reflect"
	"routing-simulator-go/structs"
	"time"
)

// State thread
func State(
	vertex *structs.Vertex,
	sender_channel chan structs.ReadOp,
	reader_channel chan structs.WriteOp,
	forwarder_channel chan structs.NextHopOp,
	print_channel chan string,
) {
	for {
		select {

		case readOp := <-sender_channel:

			// Setup package
			pack := &structs.Package{Id: vertex.Id, Pairs: []*structs.Pair{}}

			// Collect pairs
			for i := 0; i < len(vertex.RoutingTable); i++ {

				// Add pair only if changed flag (and not current vertex)
				if vertex.RoutingTable[i].Changed == true && i != vertex.Id {

					// Reset flag
					vertex.RoutingTable[i].Changed = false

					// Add to package new pair
					pair := &structs.Pair{Id: i, Cost: vertex.RoutingTable[i].Cost}
					pack.Pairs = append(pack.Pairs, pair)
				}
			}

			// if len(pack.Pairs) != 0 {
			// 	print_channel <- fmt.Sprint(
			// 		"Router ", vertex.Id, " sends out package of length ", len(pack.Pairs),
			// 	)
			// }

			// Send back package to sender
			readOp.Response <- pack

		case writeOp := <-reader_channel:

			// print_channel <- fmt.Sprint(
			// 	"Router ", vertex.Id, " received package from vertex ", writeOp.Package.Id,
			// )

			// Iterate over pairs in package
			for i := 0; i < len(writeOp.Package.Pairs); i++ {

				// Calculate new cost
				newcost := writeOp.Package.Pairs[i].Cost + 1
				source_id := writeOp.Package.Pairs[i].Id

				// If newcost smaller than current - update
				if newcost < vertex.RoutingTable[source_id].Cost && source_id != vertex.Id {
					vertex.RoutingTable[source_id].Cost = newcost
					vertex.RoutingTable[source_id].Nexthop = writeOp.Package.Id
					vertex.RoutingTable[source_id].Changed = true

					print_channel <- fmt.Sprint(
						"Router ", vertex.Id, " updated route to router ", i,
						": (cost: ", newcost, ", nexthop: ", writeOp.Package.Id, ")",
					)
				}
			}

			// Send back notification
			writeOp.Response <- true

		case next_hop_op := <-forwarder_channel:

			// Get nexthop to receiver to which host sends package
			nexthop := vertex.RoutingTable[next_hop_op.RouterId].Nexthop
			next_hop_op.Response <- nexthop
		}
	}
}

// Queue thread
func Queue(
	vertex *structs.Vertex,
	queue_channel chan structs.QueueOp,
	dequeue_channel chan structs.DequeueOp,
) {
	package_queue := []structs.HostPackage{}

	for {
		select {

		case queue_op := <-queue_channel:

			// Append package to queue
			package_queue = append(package_queue, *queue_op.HostPackage)
			queue_op.Response <- true

		case dequeue_op := <-dequeue_channel:

			// Dequeue first item if exists
			if len(package_queue) != 0 {
				host_package := package_queue[0]
				package_queue = append(package_queue[:0], package_queue[1:]...)
				dequeue_op.Response <- &host_package

			} else {
				dequeue_op.Response <- nil
			}
		}
	}
}

// Sender thread
func Sender(
	vertex *structs.Vertex,
	wait_limit int,
	out_channels []chan *structs.Package,
	read_channel chan structs.ReadOp,
) {

	rand.Seed(time.Now().UnixNano())
	readOp := structs.ReadOp{Response: make(chan *structs.Package)}

	for {

		// Wait random amount of milliseconds
		delay := rand.Intn(wait_limit)
		time.Sleep(time.Duration(float64(delay) * float64(time.Millisecond)))

		// Access routing table and get packages to be sent without blocking
		read_channel <- readOp
		pack := <-readOp.Response

		// If something changed them send
		if len(pack.Pairs) != 0 {

			// Send packages to neighbours
			for i := 0; i < len(vertex.Adj); i++ {
				out_channels[i] <- pack
			}
		}
	}
}

// Receiver thread
func Receiver(
	vertex *structs.Vertex,
	in_channels []chan *structs.Package,
	write_channel chan structs.WriteOp,
) {

	// Selector over input channels
	incases := make([]reflect.SelectCase, len(in_channels))

	// Bind channels to select cases
	for i, in_channel := range in_channels {
		incases[i] = reflect.SelectCase{Dir: reflect.SelectRecv, Chan: reflect.ValueOf(in_channel)}
	}

	for {

		// Receive package
		_, value, _ := reflect.Select(incases)
		pack := value.Interface().(*structs.Package)

		// Access routing table to update
		write_package := structs.WriteOp{Package: pack, Response: make(chan bool)}
		write_channel <- write_package
		<-write_package.Response
	}
}

// Host thread
func Host(
	address structs.Address,
	hosts []structs.Address,
	forwarder_sender_channel chan *structs.HostPackage,
	forwarder_receiver_channel chan *structs.HostPackage,
	wait_limit int,
	print_channel chan string,
) {
	rand.Seed(time.Now().UnixNano())

	// Choosing random host to send a host package to
	recAddr := structs.Address{RouterId: address.RouterId, HostId: address.HostId}

	for recAddr.RouterId == address.RouterId && recAddr.HostId == address.HostId {
		recAddr = hosts[rand.Intn(len(hosts))]
	}

	// Creating package and sending it to router forwarder
	host_package := structs.HostPackage{SenderAddr: address, ReceiverAddr: recAddr, VisitedRouters: []int{}}
	forwarder_sender_channel <- &host_package

	for {
		// Receive package from forwarder
		rec_package := <-forwarder_receiver_channel

		print_channel <- fmt.Sprint(
			"Host ", address, " received package from ", rec_package.SenderAddr,
			" with path: ", rec_package.VisitedRouters,
		)

		// Send package back to sender
		res_package := structs.HostPackage{SenderAddr: address, ReceiverAddr: rec_package.SenderAddr, VisitedRouters: []int{}}

		// Wait random amount of milliseconds
		delay := rand.Intn(wait_limit)
		time.Sleep(time.Duration(float64(delay) * float64(time.Millisecond)))

		// Print package
		// print_channel <- fmt.Sprint(
		// 	"Host ", address, " sends package to ", res_package.ReceiverAddr,
		// 	" with path: ", res_package.VisitedRouters,
		// )

		forwarder_sender_channel <- &res_package
	}

}

// Forwarder splitted into two threads
func ForwarderReceiver(
	vertex *structs.Vertex,
	in_channels []chan *structs.HostPackage,
	queue_channel chan structs.QueueOp,
	print_channel chan string,
) {

	// Selector over input channels
	incases := make([]reflect.SelectCase, len(in_channels))

	// Bind channels to select cases
	for i, in_channel := range in_channels {
		incases[i] = reflect.SelectCase{Dir: reflect.SelectRecv, Chan: reflect.ValueOf(in_channel)}
	}

	for {

		// Receive host package from adjecent router forwarders or from connected host
		_, value, _ := reflect.Select(incases)
		host_package := value.Interface().(*structs.HostPackage)

		// print_channel <- fmt.Sprint(
		// 	"Forwarder ", vertex.Id, " received package: (", host_package.SenderAddr,
		// 	", ", host_package.ReceiverAddr, ", ", host_package.VisitedRouters, ")",
		// )

		// Add current id to package's visited routers list
		host_package.VisitedRouters = append(host_package.VisitedRouters, vertex.Id)

		// Add host package to queue
		queue_op := structs.QueueOp{HostPackage: host_package, Response: make(chan bool)}
		queue_channel <- queue_op
		<-queue_op.Response
	}
}

func ForwarderSender(
	vertex *structs.Vertex,
	out_channels []structs.ForwarderOutChannel,
	hosts_channels []chan *structs.HostPackage,
	dequeue_channel chan structs.DequeueOp,
	nexthop_channel chan structs.NextHopOp,
	print_channel chan string,
) {

	dequeue_op := structs.DequeueOp{Response: make(chan *structs.HostPackage)}

	for {

		// Dequeue host package
		dequeue_channel <- dequeue_op
		host_package := <-dequeue_op.Response

		// Check whether the queue is not empty - nil package
		if host_package != nil {

			// Check if package's router id is equal to current router id
			if vertex.Id == host_package.ReceiverAddr.RouterId {

				// Send to correct host
				hosts_channels[host_package.ReceiverAddr.HostId] <- host_package

			} else {

				// Get next vertex from routing table
				next_hop_op := structs.NextHopOp{RouterId: host_package.ReceiverAddr.RouterId, Response: make(chan int)}
				nexthop_channel <- next_hop_op
				next_router_id := <-next_hop_op.Response

				// print_channel <- fmt.Sprint(
				// 	"Forwarder ", vertex.Id, " sends package: (", host_package.SenderAddr,
				// 	", ", host_package.ReceiverAddr, ", ", host_package.VisitedRouters,
				// 	") to forwarder ", next_router_id,
				// )

				// Send package to determined router
				for i := 0; i < len(out_channels); i++ {
					if out_channels[i].DestId == next_router_id {
						out_channels[i].Channel <- host_package
						break
					}
				}

			}
		}
	}
}

// Printing thread
func Printer(channel chan string, simulation_time int, done chan bool) {
	start := time.Now().Unix()

	for {
		select {

		case msg := <-channel:
			fmt.Println(msg)
		default:
			// If nothing to print skip
		}

		if time.Now().Unix()-start > int64(simulation_time) {
			done <- true
			break
		}
	}
}
