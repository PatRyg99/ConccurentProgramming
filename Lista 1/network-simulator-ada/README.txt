Kompilacja:
gnatmake main.adb

Uruchamiania:
./main.exe <n> <d> <b> <k> <ttl> <delay_limit>

n - ilość wierzchołków grafu
d - ilość dodatkowych połączeń do przodu (skróty)
b - ilość dodatkowych połączeń do tyłu
k - ilość pakietów do przesłania
ttl - (time to live) długość życia pakietu (ile razy może zmienić wierzchołek)
delay_limit - maksymalne opóźnienie, które czeka wierzchołek (ms)


Struktura programu:

- graph (adb i ads): implementacja generacji grafu skierowanego na podstawie danych 
                     parametrów n, k, spełniającego założenia zadania.

- simulation (adb i ads): implementacja przebiegu symulacji wraz z wypisywanymi podsumowaniami.

- tasks (adb i ads): implementacja wątków nadawcy, odbiorcy oraz wierzchołków grafu.

- main (adb i ads): plik uruchamiający cały program.


Krótki opis symulacji:

[Lista 1]
Graf pamiętany jest jako lista krawędzi. Każdy wątek wybierając inny wierzchołek, do którego
należy nadać pakiet, losuje na podstawie listy krawędzi, wierchołek do którego może nadać
i wykonuje jego entry send. Wątek ujścia wykonuje entry collect, które należy do odbiorcy, którego
zadaniem jest odbieranie pakietów z grafu.

[Lista 2]
Wątek kłusownika losuje dowolny wierzchołek z grafu i nadaje do niego pułapkę. Gdy ów wierzchołek
wykona randezvous z kłusownikiem pojawia się w nim pułapka niszcząca następny pakiet, który pojawi
się w wierzchołku. Dodatkowo każdy pakiet ma zmienną ttl (time to live), która oznacza ile razy
pakiet może zmienić wierzchołek. Po przekroczeniu dostępnej ilości zmian wierzchołków pakiet 
jest niszczony.
 
