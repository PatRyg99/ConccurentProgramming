// Patryk Rygiel, 250080

package threads

import (
	"fmt"
	"math/rand"
	"network-simulator-go/structs"
	"reflect"
	"time"
)

// Sender thread
func Sender(
	source *structs.Vertex,
	delay_limit int,
	channel structs.Channel,
	packages []structs.Package) {

	rand.Seed(time.Now().UnixNano())
	packages_sent := 0

	for {

		// Send given number of packages
		if packages_sent < len(packages) {

			// Wait random amount of time before sending
			delay := rand.Intn(delay_limit)
			time.Sleep(time.Duration(float64(delay) * float64(time.Millisecond)))

			// If  managed to send a package increment package id
			select {
			case channel.Chan <- &packages[packages_sent]:
				packages_sent++
			default:
				continue
			}
		}
	}
}

// Station thread
func Station(
	vertex *structs.Vertex,
	delay_limit int,
	inchannels []structs.Channel,
	outchannels []structs.Channel,
	discard_channel chan *structs.Discard,
	poacher_channel chan bool,
	printchan chan string) {

	rand.Seed(time.Now().UnixNano())
	trap := false

	// Selector over input channels
	incases := make([]reflect.SelectCase, len(inchannels)+1)

	// Bind channels to select cases
	for i, inchannel := range inchannels {
		incases[i] = reflect.SelectCase{Dir: reflect.SelectRecv, Chan: reflect.ValueOf(inchannel.Chan)}
	}

	// Add poacher channel to select
	incases[len(inchannels)] = reflect.SelectCase{Dir: reflect.SelectRecv, Chan: reflect.ValueOf(poacher_channel)}

	for {
		// Wait before receiving
		delay := rand.Intn(delay_limit)
		time.Sleep(time.Duration(float64(delay) * float64(time.Millisecond)))

		// Receive package via multi-select
		id, value, _ := reflect.Select(incases)

		// Check if selected channel is poacher
		if id == len(inchannels) {

			// Omit setting up second trap
			if trap != true {
				trap = true
				printchan <- fmt.Sprint("Poacher set trap in vertex ", vertex.Id)
			}

		} else {
			// Otherwise operate as normal package

			// Get sent package pointer
			pack := value.Interface().(*structs.Package)

			// Print message
			printchan <- fmt.Sprint("Package ", pack.Id, " is in vertex ", vertex.Id)

			// Update path lists
			pack.Vertexes = append(pack.Vertexes, vertex.Id)
			vertex.Packages = append(vertex.Packages, pack.Id)

			// Decrement ttl (time to live)
			pack.Ttl -= 1

			// Discard package if trap in station
			if trap == true {
				trap = false
				discard_channel <- &structs.Discard{PackageId: pack.Id, Code: 1}

				// Discard package if ttl is 0
			} else if pack.Ttl == 0 {
				discard_channel <- &structs.Discard{PackageId: pack.Id, Code: 0}

			} else {

				// Wait before sending
				delay = rand.Intn(delay_limit)
				time.Sleep(time.Duration(float64(delay) * float64(time.Millisecond)))

				// Choose random output channel and send package
				outchannel := outchannels[rand.Intn(len(outchannels))]
				outchannel.Chan <- pack
			}
		}
	}
}

// Receiver thread
func Receiver(
	outlet *structs.Vertex,
	delay_limit int,
	k int,
	out_channel structs.Channel,
	discard_channel chan *structs.Discard,
	done chan string,
	printchan chan string) {

	rand.Seed(time.Now().UnixNano())
	packages_received := make([]int, 0)
	packages_discarded := make([]int, 0)
	packages_caught := make([]int, 0)

	for {

		// End receiving when k packages has been received
		if len(packages_received)+len(packages_discarded)+len(packages_caught) >= k {
			time.Sleep(time.Duration(float64(delay_limit) * float64(time.Millisecond)))
			done <- fmt.Sprint(
				"Packages received: ", packages_received,
				"\nPackages discarded: ", packages_discarded,
				"\nPackages caught: ", packages_caught,
			)
		}

		// Sleep for random amout of milisceonds from [0, delay_limit]
		delay := rand.Intn(delay_limit)
		time.Sleep(time.Duration(float64(delay) * float64(time.Millisecond)))

		select {
		case pack := <-out_channel.Chan:
			printchan <- fmt.Sprint("Package ", pack.Id, " has been received")
			packages_received = append(packages_received, pack.Id)

		case discard := <-discard_channel:

			if discard.Code == 0 {

				// If code 0 - discard due to ttl
				printchan <- fmt.Sprint("Package ", discard.PackageId, " has been discarded (ttl expired)")
				packages_discarded = append(packages_discarded, discard.PackageId)

			} else if discard.Code == 1 {

				// If code 1 - discard due to trap set by poacher
				printchan <- fmt.Sprint("Package ", discard.PackageId, " has been caught in a trap")
				packages_caught = append(packages_caught, discard.PackageId)
			}

		default:
			continue
		}
	}
}

// Poacher thread
func Poacher(
	stations chan bool,
	delay_limit int) {
	rand.Seed(time.Now().UnixNano())

	for {

		// Sleep 10x more than station thread
		delay := rand.Intn(delay_limit)
		time.Sleep(time.Duration(7 * float64(delay) * float64(time.Millisecond)))

		// Set trap in random station (all stations listen to this channel)
		stations <- true
	}
}

// Printing thread
func Printer(channel chan string) {
	for {
		msg := <-channel
		fmt.Println(msg)
	}
}
