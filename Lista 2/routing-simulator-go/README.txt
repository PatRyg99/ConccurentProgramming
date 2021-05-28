Aby uruchomić program należy wywołać:

go run main.go <n> <d> <wait_limit> <simulation_time>

n - ilość wierzchołków grafu
d - ilość dodatkowych połączeń (skróty)
max_hosts - maksymalna ilość hostów na jeden wierzchołek
wait_limit [ms] - maksymalny czas jaki sender czeka pomiędzy rozsyłaniem pakietów
simulation_time [s] - czas trwania symulacji


Struktura programu:

- graph: folder zawiera plik graph.go, w którym generowany jest graf
         na podstawie danych parametrów n, d, spełniający założenia zadania.

- structs: folder zawiera plik structs.go, w którym znajdują się stuktury danych
           używane w programie.

- simulation: folder zawiera plik simulation.go, w którym znajduje się implementacja przebiegu
              symulacji oraz deklaracja wątków z odpowiednim połączeniem przy użyciu kanałów.

- threads: folder zawiera plik threads.go, w którym znajduje się implementacja wątków
           sender, receiver, forwarder_sender, forwarder_receiver
           oraz wątki state, queue, które są stateful goroutine odpowiadającą za dostęp
           do kolejno routing table oraz kolejki pakietów wysyłanych przez forwardery. 


Krótki opis implementacji:

[Lista 3]
Wygenerowany graf pamiętany jest jako lista sąsiedztwa. Każdy wierzchołek grafu
składa się z 3 wątków: sender, receiver oraz state. Wątek state jest stateful goroutine
i jako jedyny dokonuje modyfikacji pola routing table. Nasłuchuje on wątków sendera
oraz readera udzielając im synchronicznie dostępu do zasobów, dzięki czemu żadne
zmiany nie są zagłuszane przez wątki działające asynchronicznie. Wątek sendera prosi
wątek state o listę zmienionych pól w routing table, następnie już sam rozsyła je
do sąsiadów (nie blokując dostępu do routing table). Wątek receivera Nasłuchuje
nadchodzących pakietów od sąsiadów. Gdy takowy nadejdzie przekazuje on go do wątku 
state, który odpowiednio na jego podstawie uaktualnia routing table.

[Lista 4]
Dodane zostały cztery nowe wątki. W każdym wierzchołku działają dodatkowo wątki 
forwarder_sender, który wyjmuje pakiety od hostów z kolejki i wysyła do kolejnego
wierzchołka lub do hosta gdy jest on podłączony do tego wierzchołka, 
oraz wątek forwarder_receiver, który odbiera pakiety od sąsiednich wierzchołków
oraz hostów i dodaje je do kolejki. Dodatkowo w każdym wierzchołku działa wątek
queue, który jest implementacją kolejki pakietów jako stateful goroutine, odpowiada
on za dostęp wątków forwardera do kolejki. Ostatnim dodanym wątkiem jest wątek
hosta, który jest połączony tylko i wyłącznie ze swoim routerem i nadaje do niego
pakiety oraz je odbiera.
