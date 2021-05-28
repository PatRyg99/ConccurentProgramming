-- Patryk Rygiel, 250080

with ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Discrete_Random;

with Ada.Containers.Synchronized_Queue_Interfaces;
with Ada.Containers.Unbounded_Synchronized_Queues;

with Graph; use Graph;
with Simulation; use Simulation;

package body Tasks is

    procedure Launch(
        n, wait_limit, simulation_time : Integer; 
        graphEdges : Edges; 
        hosts : IntArrayType;
        routingTables : out RoutingTableArray) is

        -- DEFINING QUEUE
        type HostPack is record
            senderRouterId : Integer;
            senderHostId : Integer;
            recRouterId : Integer;
            recHostId : Integer;
            visited : IntArrayType(0..n-1);
        end record;

        package HostPackageQueuesInterface is new Ada.Containers.Synchronized_Queue_Interfaces
            (Element_Type => HostPack);

        package HostPackageQueues is new Ada.Containers.Unbounded_Synchronized_Queues
            (Queue_Interfaces => HostPackageQueuesInterface);

        
        -- SPLITTING FULL ROUTING TABLE INTO VERTEX ONES
        function InitRoutingTable(id : Integer) return RoutingTableType is
            routingTable : RoutingTableType(0..n-1);
        begin
            for i in 0..n-1 loop
               routingTable(i) := routingTables(id, i);
            end loop;

            return routingTable;
        end InitRoutingTable;

        -- SUMMING NUMBER OF HOSTS TO ALLOCATE
        function CountHosts(hosts : IntArrayType) return Integer is
            sum : Integer;
        begin
            sum := 0;

            for i in hosts'Range loop
                sum := sum + hosts(i);   
            end loop;

            return sum;
        end CountHosts;

        function GetHostId(hosts : IntArrayType; routerId, hostId : Integer) return Integer is
            id : Integer;
        begin
            id := 0;

            for i in hosts'Range loop
               if routerId = i then

                    for j in 0..hosts(i)-1 loop
                        if hostId = j then
                            exit;
                        end if;

                        id := id + 1;
                    end loop;

                    exit;
               end if;

               id := id + hosts(i);
            end loop;

            return id;
        end GetHostId;

        -- DECLARATIONS

        -- Protected objects
        protected type ProtectedRoutingTableType(Id : Integer) is
            procedure UpdateRoutingTable(source : Integer; pack : Pairs);
            procedure GetRoutingPackage(pack : out Pairs; empty : out Boolean);
            function GetTable return RoutingTableType;

        private
            routingTable : RoutingTableType(0..n-1) := InitRoutingTable(Id);
        end ProtectedRoutingTableType;

        -- Tasks
        task type SenderType(Id : Integer);

        task type ReceiverType(Id : Integer) is
            entry Send(source : in Integer; pack : in Pairs);
            entry Close;
        end ReceiverType;

        task type HostType(RouterId, HostId : Integer) is
            entry Send(pack : in HostPack);
            entry Close;
        end HostType;

        task type ForwarderSenderType(Id : Integer);

        task type ForwarderReceiverType(Id : Integer) is
            entry Send(pack : in HostPack);
            entry Close;
        end ForwarderReceiverType;

        task type PrinterType is
            entry PrintRouterUpdate(receiver, sender, cost, nexthop : Integer);
            entry PrintHostReceived(pack : HostPack);
            entry Close;
        end PrinterType;

        task type TerminatorType;


        -- Array types
        type ProtectedRoutingTableArrayType is array (Integer range <>) of access ProtectedRoutingTableType;
        type AccessProtectedRoutingTableArray is access ProtectedRoutingTableArrayType;

        type SenderArrayType is array (Integer range <>) of access SenderType;
        type AccessSenderArray is access SenderArrayType;

        type ReceiverArrayType is array (Integer range <>) of access ReceiverType;
        type AccessReceiverArray is access ReceiverArrayType;

        type ForwarderSenderArrayType is array (Integer range <>) of access ForwarderSenderType;
        type AccessForwarderSenderArray is access ForwarderSenderArrayType;

        type ForwarderReceiverArrayType is array (Integer range <>) of access ForwarderReceiverType;
        type AccessForwarderReceiverArray is access ForwarderReceiverArrayType; 
        
        type HostArrayType is array (Integer range <>) of access HostType;
        type AccessHostArray is access HostArrayType;

        -- Constructors
        function InitProtectedRoutingTable(n : Integer) return AccessProtectedRoutingTableArray is
            ProtectedRoutingTableArrayPtr : AccessProtectedRoutingTableArray;
        begin
            ProtectedRoutingTableArrayPtr := new ProtectedRoutingTableArrayType(0..n-1);

            for i in ProtectedRoutingTableArrayPtr.all'Range loop
               ProtectedRoutingTableArrayPtr.all(i) := new ProtectedRoutingTableType(i);
            end loop;

            return ProtectedRoutingTableArrayPtr;
        end;

        function InitSenderTasks(n : Integer) return AccessSenderArray is
            SenderArrayPtr : AccessSenderArray;
        begin
            SenderArrayPtr := new SenderArrayType(0..n-1);

            for i in SenderArrayPtr.all'Range loop
                SenderArrayPtr.all(i) := new SenderType(i);
            end loop;

            return SenderArrayPtr;
        end;

        function InitReceiverTasks(n : Integer) return AccessReceiverArray is
            ReceiverArrayPtr : AccessReceiverArray;
        begin
            ReceiverArrayPtr := new ReceiverArrayType(0..n-1);

            for i in ReceiverArrayPtr.all'Range loop
                ReceiverArrayPtr.all(i) := new ReceiverType(i);
            end loop;

            return ReceiverArrayPtr;
        end;

        function InitForwarderSenderTasks(n : Integer) return AccessForwarderSenderArray is
            ForwarderSenderArrayPtr : AccessForwarderSenderArray;
        begin
            ForwarderSenderArrayPtr := new ForwarderSenderArrayType(0..n-1);

            for i in ForwarderSenderArrayPtr.all'Range loop
                ForwarderSenderArrayPtr.all(i) := new ForwarderSenderType(i);
            end loop;

            return ForwarderSenderArrayPtr;
        end;

        function InitForwarderReceiverTasks(n : Integer) return AccessForwarderReceiverArray is
            ForwarderReceiverArrayPtr : AccessForwarderReceiverArray;
        begin
            ForwarderReceiverArrayPtr := new ForwarderReceiverArrayType(0..n-1);

            for i in ForwarderReceiverArrayPtr.all'Range loop
                ForwarderReceiverArrayPtr.all(i) := new ForwarderReceiverType(i);
            end loop;

            return ForwarderReceiverArrayPtr;
        end;

        function InitHostTasks(hosts : IntArrayType) return AccessHostArray is
            HostArrayPtr : AccessHostArray;
            elements : Integer;
            counter : Integer;
        begin
            elements := 0;
            counter := 0;

            for i in hosts'Range loop
                elements := elements + hosts(i);   
            end loop;

            HostArrayPtr := new HostArrayType(0..elements);

            for i in 0..n-1 loop
                for j in 0..hosts(i)-1 loop
                    HostArrayPtr.all(counter) := new HostType(i, j);
                    counter := counter + 1;
                end loop;
            end loop;

            return HostArrayPtr;
        end;

        -- Objects
        ProtectedRoutingTableArray : ProtectedRoutingTableArrayType(0 .. n-1);
        QueueArray : array(0 .. n-1) of HostPackageQueues.Queue;

        SenderArray : SenderArrayType(0 .. n-1);
        ReceiverArray : ReceiverArrayType(0 .. n-1);

        ForwarderSenderArray : ForwarderSenderArrayType(0 .. n-1);
        ForwarderReceiverArray : ForwarderReceiverArrayType(0 .. n-1);

        HostArray : HostArrayType(0 .. CountHosts(hosts));

        Printer : PrinterType;
        Terminator : TerminatorType;

        -- Random number generator
        type randRange is new Integer range 0..wait_limit + CountHosts(hosts);
        package Rand_Int is new Ada.Numerics.Discrete_Random(randRange);
        use Rand_Int;

        gen : Generator;

        -- DEFINITIONS

        -- Protected routing table access
        protected body ProtectedRoutingTableType is

            procedure UpdateRoutingTable(source : Integer; pack : Pairs) is
                newcost : Integer;
            begin
                -- put_line("Vertex" & Integer'Image(id) & " received package from vertex" & Integer'Image(source));

                for i in 0 .. n-1 loop

                    -- If pair not empty - calculate new cost
                    if pack(i).id /= -1 then
                        newcost := 1 + pack(i).cost;

                        -- If new cost smaller then previous - update route
                        if newcost < routingTable(i).cost then
                            routingTable(i).cost := newcost;
                            routingTable(i).nexthop := source;
                            routingTable(i).changed := 1;

                            Printer.PrintRouterUpdate(id, i, newcost, source);

                        end if;
                    end if;
                end loop;

            end UpdateRoutingTable;

            procedure GetRoutingPackage(pack : out Pairs; empty : out Boolean) is
                num_pack : Integer;
            begin
                
                num_pack := 0;

                for i in 0 .. n-1 loop

                    -- Check whether routing table entry for vertex i changed
                    if routingTable(i).changed = 1 and i /= id then
                        pack(i).id := i;
                        pack(i).cost := routingTable(i).cost;
                        routingTable(i).changed := 0;

                        num_pack := num_pack + 1;

                    -- If not send empty pair
                    else
                        pack(i).id := -1;
                        pack(i).cost := -1;
                    end if;

                end loop;

                -- Print message
                if num_pack = 0 then
                    -- put_line("Vertex" & Integer'Image(Id) & " has nothing to send");
                    empty := TRUE;
                else
                    -- put_line("Vertex" & Integer'Image(Id) & " sends out package of length" & Integer'Image(num_pack));
                    empty := FALSE;
                end if;
                
            end GetRoutingPackage;

            function GetTable return RoutingTableType is
            begin
                return routingTable;
            end GetTable;

        end ProtectedRoutingTableType;


        -- Task sending package to neighbour routers
        task body SenderType is
            rand : Integer;
            pack : Pairs(0..n-1);
            empty : Boolean;
        begin

            loop
                -- Generate random number
                reset(gen);
                rand := Integer'Value(randRange'Image(random(gen)));

                -- Wait for random number of miliseconds
                delay 0.001 * Duration(rand mod wait_limit);
                
                -- Get package of changed entries in routing table
                ProtectedRoutingTableArray(Id).GetRoutingPackage(pack, empty);

                -- Send package to all neighbours if package not empty
                if empty = FALSE then
                    for i in 0..graphEdges'length - 1 loop
                        if graphEdges(i).v = Id then
                            ReceiverArray(graphEdges(i).u).Send(Id, pack);

                        elsif graphEdges(i).u = Id then
                            ReceiverArray(graphEdges(i).v).Send(Id, pack);
                        end if;
                    end loop;
                end if;

                -- Check whether receiver closed - if so end sender
                if ReceiverArray(Id)'Terminated then
                    exit;
                end if;

            end loop;
        end SenderType;


        -- Task receiving packages from neighbour routers
        task body ReceiverType is
        begin
            loop
                select
                    -- Accept package from neighbour and update routing table
                    accept Send(source : in Integer; pack : in Pairs) do
                        ProtectedRoutingTableArray(Id).UpdateRoutingTable(source, pack);
                    end;
                or
                    -- Close receiver if simulation time expired
                    accept Close;
                    exit;

                end select;
            end loop;

        end ReceiverType;


        -- Task simulating a host connected to one of routers
        task body HostType is
            rand : Integer;
            rand_router : Integer;
            rand_host : Integer; 
            host_pack : HostPack;
            rec_pack : HostPack;
            visited : IntArrayType(0..n-1) := (others => -1);
        begin
            -- Delay at start
            delay 0.005;

            -- Choose random host to send a package to
            reset(gen);
            rand_router := Integer'Value(randRange'Image(random(gen))) mod n;
            rand_host := Integer'Value(randRange'Image(random(gen))) mod hosts(rand_router);

            -- Setup host package to sent
            host_pack.SenderRouterId := RouterId;
            host_pack.SenderHostId := HostId;
            host_pack.RecRouterId := rand_router;
            host_pack.RecHostId := rand_host;
            host_pack.visited := visited;
            ForwarderReceiverArray(RouterId).send(host_pack);

            loop

                select
                    -- Accept host package from router
                    accept Send(pack : in HostPack) do
                        rec_pack := pack; 
                    end;
                or
                    -- Close host if simulation time expired
                    accept Close;
                    exit;

                end select;

                -- Print received pack
                Printer.PrintHostReceived(rec_pack);

                -- Wait random amount of time
                reset(gen);
                rand := Integer'Value(randRange'Image(random(gen)));
                delay 0.001 * Duration(rand mod wait_limit);

                host_pack.RecRouterId := rec_pack.SenderRouterId;
                host_pack.RecHostId := rec_pack.SenderHostId;
                host_pack.visited := visited;

                ForwarderReceiverArray(RouterId).send(host_pack);
            end loop;
        end HostType;


        -- Task sending host packages
        task body ForwarderSenderType is
            fetched : Integer;
            pack : HostPack;
            host_id : Integer;
            router_id : Integer;
        begin
            -- Delay at start
            delay 0.005;

            loop
                fetched := 0;

                -- Try to dequeue
                select 
                    QueueArray(Id).Dequeue(pack);
                    fetched := 1;
                or 
                    delay 0.001;
                end select;
                
                -- If nothing to dequeue skip
                if fetched = 1 then

                    -- Append current router to visited
                    for i in 0..n-1 loop
                       if pack.visited(i) = -1 then
                            pack.visited(i) := Id;
                            exit;
                       end if;
                    end loop;

                    -- If pack's receiver router equal to current, send to host
                    if pack.recRouterId = Id then

                        host_id := GetHostId(hosts, Id, pack.recHostId);
                        HostArray(host_id).send(pack);

                    -- Otherwise forward it over shortest path further
                    else 
                        router_id := ProtectedRoutingTableArray(Id).GetTable(pack.recRouterId).nexthop;
                        ForwarderReceiverArray(router_id).send(pack);
                    end if;

                end if;

                -- Check whether receiver closed - if so end sender
                if ForwarderReceiverArray(Id)'Terminated then
                    exit;
                end if;

            end loop;
        end ForwarderSenderType;


        -- Task receiving host packages
        task body ForwarderReceiverType is
        begin
            loop
                select 
                    -- Receive package from hosts or neighbouring forwarders and enqueue it
                    accept Send(pack : HostPack) do
                        QueueArray(Id).Enqueue(pack);
                    end;

                    or
                    -- Close forwarder receiver if simulation time expired
                    accept Close;
                    exit;
                end select;
            end loop;
        end ForwarderReceiverType;

        -- Printer task
        task body PrinterType is
        begin

            loop
                select 
                    accept PrintRouterUpdate(receiver, sender, cost, nexthop : Integer) do
                        put_line(
                            "Router" & Integer'Image(receiver) & " updated route to router"
                            & Integer'Image(sender) & ": (cost:" & Integer'Image(cost) &
                            " , nexthop:" & Integer'Image(nexthop) & " )"
                        );
                    end;

                or
                    accept PrintHostReceived(pack : HostPack) do
                        put(
                            "Host (" & Integer'Image(pack.RecRouterId) & "," & Integer'Image(pack.RecHostId) & 
                            ") received package from (" & Integer'Image(pack.SenderRouterId) & 
                            "," & Integer'Image(pack.senderHostId) & ") with path: ["
                        );

                        for i in 0..n-1 loop
                        if pack.visited(i) /= -1 then
                            put("" & Integer'Image(pack.visited(i)) & ",");
                        else 
                            exit;
                        end if;
                        end loop;

                        put_line("]");
                    end;

                or
                    accept Close;
                    exit;
                
                end select;
            end loop;
        end;

        -- Terminator task to end simulation after given time elapsed
        task body TerminatorType is
        begin
            delay Duration(simulation_time);

            -- Close hosts
            for i in 0..CountHosts(hosts)-1 loop
                HostArray(i).Close;
            end loop;

            put_line("Hosts closed");

            -- Close recievers
            for i in 0..n-1 loop
               ReceiverArray(i).Close;
               ForwarderReceiverArray(i).Close;
            end loop;

            put_line("Receivers closed");

            Printer.Close;

            -- Fetch updated routing tables
            for i in 0..n-1 loop
                for j in 0..n-1 loop
                   routingTables(i, j) := ProtectedRoutingTableArray(i).getTable(j);
                end loop;
                
            end loop;

        end TerminatorType;

    begin
        ProtectedRoutingTableArray := InitProtectedRoutingTable(n).all; 

        ForwarderReceiverArray := InitForwarderReceiverTasks(n).all;
        ForwarderSenderArray := InitForwarderSenderTasks(n).all;
        
        HostArray := InitHostTasks(hosts).all;
        
        ReceiverArray := InitReceiverTasks(n).all;
        SenderArray := InitSenderTasks(n).all;

    end Launch;

end Tasks;