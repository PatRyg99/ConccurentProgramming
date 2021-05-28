// Patryk Rygiel, 250080

package structs

type Package struct {
	Id       int
	Ttl      int
	Vertexes []int
}

type Channel struct {
	Chan chan *Package
}

type Vertex struct {
	Id       int
	Adj      []int
	Packages []int
	Inchans  []Channel
	Outchans []Channel
}

type Discard struct {
	PackageId int
	Code      int
}
