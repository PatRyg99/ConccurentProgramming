Kompilacja:
gnatmake main.adb

Uruchamiania:
./main.exe <n> <d> <max_hosts> <wait_limit> <simulation_time>

n - ilość wierzchołków grafu
d - ilość dodatkowych połączeń (skróty)
max_hosts - maksymalna ilość hostów na jeden wierzchołek
wait_limit [ms] - maksymalny czas jaki sender czeka pomiędzy rozsyłaniem pakietów
simulation_time [s] - czas trwania symulacji


Struktura programu:

- graph (adb i ads): implementacja generacji grafu na podstawie danych 
                     parametrów n, d, spełniającego założenia zadania.

- simulation (adb i ads): implementacja przebiegu symulacji wraz z wypisywanymi podsumowaniami.

- tasks (adb i ads): implementacja wątków sendera, receivera, forwarder_sendera, forwarder_receivera oraz routing table w postaci obiektu protected.

- main (adb i ads): plik uruchamiający cały program.


Krótki opis symulacji:

[Lista 3]
Graf pamiętany jest jako lista krawędzi. Każdy wierzchołek w grafie składa się z dwóch wątków:
sender i reciever oraz obiektu protected, który odpowiada za obsługę routing table. Wątek sender
co pewien czas się budzi i wysyła zapytanie do obiektu routing table o listę zmienionych od ostatniego
wysyłania elementów routing table. Następnie jeśli ów lista nie jest pusta, nadaje on ją do wszystkich
sąsiadów. Wątek reciever czeka na inicjalizowanie randezvous przez wątki nadawców sąsiadów. Gdy otrzyma
pakiet od sąsiada przekazuje on go do obiektu routing table, który odpowiednio na podstawie przesłanych
informacji dokonuje uaktualnienia routing table. Symulacja trwa przekazaną jako parametr ilość sekund i
po upływie tego czasu wątek terminator zamyka pozostałe wątki i drukowane są aktualne routing table
dla każdego wierzchołka.

[Lista 4]
Dodane zostały trzy nowe wątki: forwarder receiver, forwarder sender oras host. Host jest wątkiem
podpiętym do jednego z routerów, odbiera on pakiety nadanego do niego od forwardera w podpiętym
routerze i odsyła do hosta, który nadał ów pakiet, pakiet zwrotny, który pozwala zaobserwować 
skracanie się ścieżki podróży poprzez drukowanie przekazywanych pakietów. Wątek forwarder receiver
odbiera pakiety od forwarderów w sąsiednich routerach oraz od podpiętych hostów do routera, którego
jest on forwarderem, i dodaje je do kolejki pakietów. Wątek forwarder sender wyciąga pakiety z kolejki,
dodaje obecne id routera do odwiedzonych routerów, a następnie, sprawdza id routera docelowego dla pakietu.
Gdy jest ono równe id routera, do którego jest on podpięty, to przesyła pakiet do podpiętego hosta.
W przeciwnym wypadku przesyła on zapytania do routing table o sąsiada na najbliższej ścieżce do ów routera
i nadaje pakiet do forwardera w ów routerze.
 