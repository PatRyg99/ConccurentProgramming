// Patryk Rygiel, 250080

package structs

type Vertex struct {
	Id                   int
	Adj                  []int
	Hosts                int
	RoutingTable         []RoutingTableVertex
	OutChannels          []chan *Package
	InChannels           []chan *Package
	OutForwarderChannels []ForwarderOutChannel
	InForwarderChannels  []chan *HostPackage
}

type RoutingTableVertex struct {
	Nexthop int
	Cost    int
	Changed bool
}

// Forwarder channel
type ForwarderOutChannel struct {
	DestId  int
	Channel chan *HostPackage
}

// Router packages
type Pair struct {
	Id   int
	Cost int
}

type Package struct {
	Id    int
	Pairs []*Pair
}

// Host packages
type Address struct {
	RouterId int
	HostId   int
}

type HostPackage struct {
	SenderAddr     Address
	ReceiverAddr   Address
	VisitedRouters []int
}

// State thread communication
type ReadOp struct {
	Response chan *Package
}

type WriteOp struct {
	Package  *Package
	Response chan bool
}

type NextHopOp struct {
	RouterId int
	Response chan int
}

// Queue thread communication
type DequeueOp struct {
	Response chan *HostPackage
}

type QueueOp struct {
	HostPackage *HostPackage
	Response    chan bool
}
