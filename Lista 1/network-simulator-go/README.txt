Aby uruchomić program należy wywołać:

go run main.go <n> <d> <b> <k> <ttl> <delay_limit>

n - ilość wierzchołków grafu
d - ilość dodatkowych połączeń do przodu (skróty)
b - ilość dodatkowych połączeń do tyłu
k - ilość pakietów do przesłania
ttl - (time to live) długość życia pakietu (ile razy może zmienić wierzchołek)
delay_limit - maksymalne opóźnienie, które czeka wierzchołek (ms)


Struktura programu:

- graph: folder zawiera plik graph.go, w którym generowany jest graf skierowany
         na podstawie danych parametrów n, k, spełniający założenia zadania.

- structs: folder zawiera plik structs.go, w którym znajdują się stuktury danych
           używane w programie.

- simulation: folder zaiwera plik simulation.go, w którym znajduje się implementacja przebiegu
              symulacji oraz deklaracja wątków z odpowiednim połączeniem przy użyciu kanałów.

- threads: folder zawieta plik threads.go, w którym znajduje się implementacja wątków
           nadawcy, odbiorcy, wierzchołków grafu (nazwanych stacjami - stations), wątku
           drukującego oraz kłusownika.


Krótki opis implementacji:

[Lista 1]
Wygenerowany graf pamiętany jest jako lista sąsiedztwa. Każdy wierzchołek grafu posiada jako 
krawędzie wchodzące kanały z których odbiera oraz jako krawędzie wychodzące kanały na które nadaje.
Każda krawędź grafu jest osobnym kanałem. Wierzchołek wybiera kanał, z którego odbiera pakietów
przy użyciu reflect.select, który pozwala na słuchanie zmiennej listy kanałów. 

[Lista 2]
Wątek kłusownika nadaje pułapkę na kanał, który nasłuchuje każda ze stacji. Gdy poprzez polecenie
select wybrany zostanie kanał od kłusownika w stacji stawiana jest pułapka niszcząca następny wchodzący do 
niej pakiet. Każdy pakiet ma także parametr ttl, który dekrementowany jest z każdą zmianą stacji. 
Przy osiągnięciu 0, stacja w której obecnie znajduje się pakiet niszczy go.