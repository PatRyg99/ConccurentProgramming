-- Patryk Rygiel, 250080

with ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Discrete_Random;
with Graph; use Graph;
with Simulation; use Simulation;

package body Tasks is

    procedure Launch(
        n, k, tts, delay_limit : Integer; 
        graphEdges : Edges; 
        vertexes, packages : out ItemArray;
        packagesState : out IntArray) is

        -- DECLARATIONS

        -- Tasks
        task type SenderType;

        task type ReceiverType is
            entry Collect(pkgId : in Integer);
            entry Discard(pkgId : in Integer);
            entry Trapped(pkgId : in Integer);
        end ReceiverType;

        task type NodeType(Id : Integer) is 
            entry Send(pkgId : in Integer);
            entry SetTrap;
            entry Close;
        end NodeType;

        task type PoacherType;

        -- Tasks array
        type NodeArrayType is array (Integer range <>) of access NodeType;
        type AccessNodeArray is access NodeArrayType;

        -- Constructors
        function InitTasks(n : Integer) return AccessNodeArray is
            NodesArrayPtr : AccessNodeArray;
        begin
            NodesArrayPtr := new NodeArrayType(0..n-1);

            for i in NodesArrayPtr.all'Range loop
                NodesArrayPtr.all(i) := new NodeType(i);
            end loop;

            return NodesArrayPtr;
        end;

        -- Task objects
        NodeArray : NodeArrayType(0 .. n-1);
        Sender : SenderType;
        Receiver : ReceiverType;
        Poacher : PoacherType;

        -- Random number generator
        type randRange is new Integer range 0..n + delay_limit;
        package Rand_Int is new Ada.Numerics.Discrete_Random(randRange);
        use Rand_Int;

        gen : Generator;

        -- TTS list
        TTSArray : IntArray(0 .. packages'Length-1) := (others => tts);


        -- DEFINITIONS

        -- Task sending packages into the graph
        task body SenderType is
            rand : Integer;
            pkgId : Integer;
        begin
            pkgId := 0;

            loop
                -- If all packages have been sent then end
                if pkgId > k-1 then
                    exit;
                end if;

                -- Generate random number
                reset(gen);
                rand := Integer'Value(randRange'Image(random(gen)));

                -- Wait for random number of miliseconds
                delay 0.001 * Duration(rand mod delay_limit);

                NodeArray(0).Send(pkgId);
                pkgId := pkgId + 1;

            end loop;
        end SenderType;


        -- Task receving and sending packages within a graph - vertex
        task body NodeType is
            rand : Integer;
            currPkg : Integer;
            destId : Integer;
            iter : Integer;
            edgeIter : Integer;
            trap : Boolean;
        begin
            currPkg := -1;
            trap := false;

            loop
                -- Generate random number
                reset(gen);
                rand := Integer'Value(randRange'Image(random(gen)));

                -- Wait for random number of miliseconds
                delay 0.001 * Duration(rand mod delay_limit);

                -- If node is not empty begin sending
                if currPkg /= -1 then

                    if Id = n-1 then
                        Receiver.Collect(currPkg);
                    else
                        iter := 0;
                        edgeIter := 0;
                        rand := rand mod graphEdges'length;

                        -- Choose random edge from current vertex
                        while edgeIter - 1 < rand loop
                            
                            if graphEdges(iter).src = Id then
                                destId := graphEdges(iter).dest;
                                edgeIter := edgeIter + 1;
                            end if;
                            
                            iter := (iter + 1) mod graphEdges'length;
                        end loop;

                        NodeArray(destId).send(currPkg);
                        
                    end if;
                    
                    currPkg := -1;
                
                -- If node is empty change to select mode - if no pending skip
                else
                    select
                        accept Send(PkgId : in Integer) do
                            -- Accept incoming package
                            put_line("Package" & Integer'Image(PkgId) & " is in vertex" & Integer'Image(Id));              
                            currPkg := PkgId;
                        end;
                    or
                        accept SetTrap do
                            -- Setting up trap in vertex
                            put_line("Poacher set trap in vertex" & Integer'Image(Id));   
                            trap := true;
                        end;
                    or
                        accept Close;
                        exit;
                    end select;

                    -- Go to sending only if selected package
                    if currPkg /= -1 then

                        -- Update vertex visitors
                        for i in 0 .. k-1 loop
                            if vertexes(Id, i) = -1 then
                                vertexes(Id, i) := currPkg;
                                exit;
                            end if;
                        end loop;

                        -- Update package route
                        for i in 0 .. n-1 loop
                            if packages(currPkg, i) = -1 then
                                packages(currPkg, i) := Id;
                                exit;
                            end if;
                        end loop;

                        -- Decrement time to live
                        TTSArray(currPkg) := TTSArray(currPkg) - 1;

                        
                        -- If trap in current vertex - discard package and trap
                        if trap = true then
                            Receiver.trapped(currPkg);
                            currPkg := -1;
                            trap := false;
                        else
                            -- If tts 0 - discard package
                            if TTSArray(currPkg) = 0 then
                                Receiver.discard(currPkg);
                                currPkg := -1;
                            end if;
                        end if;
                    end if;

                end if;
                
            end loop;
        end NodeType;


        -- Task colecting packages from graph
        task body ReceiverType is
            rand : Integer;
            packagesEnded : Integer;
        begin
            packagesEnded := 0;

            loop
                -- Generate random number
                reset(gen);
                rand := Integer'Value(randRange'Image(random(gen)));

                -- Wait for random number of miliseconds
                delay 0.001 * Duration(rand mod delay_limit);

                -- If all packages received, discarded, trapped - end all tasks
                if packagesEnded = k then
                    for i in 0 .. n-1 loop
                        NodeArray(i).Close;
                    end loop;
                    exit;
                end if;

                -- Collect package from last node if pending
                select 
                    accept Collect(PkgId : in Integer) do
                        put_line("Package" & Integer'Image(PkgId) & " has been received");
                        packagesEnded := packagesEnded + 1;
                        packagesState(PkgId) := 1;
                    end;
                or
                    accept Discard(PkgId : in Integer) do 
                        put_line("Package" & Integer'Image(PkgId) & " has been discarded (ttl expired)"); 
                        packagesEnded := packagesEnded + 1;
                        packagesState(PkgId) := 2;
                    end;
                or
                    accept Trapped(PkgId : in Integer) do
                        put_line("Package" & Integer'Image(PkgId) & " has been caught in a trap"); 
                        packagesEnded := packagesEnded + 1;
                        packagesState(PkgId) := 3;
                    end;
                else
                    null;
                end select;

            end loop;
        end ReceiverType;

        -- Poacher task
        task body PoacherType is
            rand : Integer;
            randId : Integer;
        begin
            loop 

                -- Generate random number
                reset(gen);
                rand := Integer'Value(randRange'Image(random(gen)));

                -- Wait for random number of miliseconds (7x more)
                delay 0.007 * Duration(rand mod delay_limit);

                -- Set trap in random node
                randId := rand mod n;

                if not NodeArray(randId)'Terminated then
                    NodeArray(rand mod n).setTrap;
                end if;
                
                -- End poacher when receiver terminated
                if Receiver'Terminated then
                    exit;
                end if;
            
            end loop;
        end PoacherType;

    begin
        NodeArray := InitTasks(n).all;
    end Launch;

end Tasks;