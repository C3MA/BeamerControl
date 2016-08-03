-- beamer_init.lua file for the beamer control
print("Booting... Beamer v0.91")
dofile("wlancfg.lua")

global_c=nil
function netPrint(str)
  if global_c~=nil then
    global_c:send(str)
    global_c:send("\\\n")
  end
end

function startTelnetServer(dummy)
    s=net.createServer(net.TCP, 180)
    s:listen(2323,function(c)
    global_c=c
    function s_output(str)
      if(global_c~=nil)
         then global_c:send(str)
      end
    end
    -- Do not move the output, as the Beamer must be spoken to
    --node.output(s_output, 0)
    c:on("receive",function(c,l)
      node.input(l)
    end)
    c:on("disconnection",function(c)
      node.output(nil)
      global_c=nil
    end)
    netPrint("Welcome to NodeMcu world at the beamer")
    end)
end

m = mqtt.Client("beamer", 120, "", "")

function configureMqttService(c)
    m:on("connect", function(con) 
        netPrint ("MQTT connected") 
        configureInputCheck()
        m:publish("/room/beamer/ip",wifi.sta.getip(),0,0, function(conn) netPrint("Sent IP") end)
    end)
    m:on("offline", function(con) 
        netPrint ("MQTT offline") 
        node.restart()
    end)

    m:on("message", function(conn, topic, data)
      netPrint(topic .. ":" )
      if ((data ~= nil) and (topic == "/room/beamer/command")) then
        --netPrint(topic .. ":" .. data)
        if data == "OFF" then
          netPrint ("Shutdown beamer")
          uart.write(0, "* 0 IR 002\r\r")
        end
        if data == "ON" then
          netPrint ("Start Beamer")
          uart.write(0, "OKOKOKOKOK\r\r")
        end
        if data == "INPUT" then
         netPrint ("Select Input")
         uart.write(0, "* 0 IR 031\r\r")
        end
      end
    end)
    -- Start MQTT Server
    if (mqttIP ~= nil) then
        m:connect(mqttIP, 1883, 0, nil)

        tmr.alarm(2, 2000, 0, function() 
            m:subscribe("/room/beamer/#",0)
        end)
    else
        print("No Mqtt Server configured")
    end
end

-- Inform about connecting devices
function configureInputCheck()
  tmr.alarm(3, 2000, 1, function()
    -- Check the resolution in order to find a client
    uart.write(0, "* 0 IR 036\r\r")
  end)
  uart.on("data",4, function(data)
    if (string.match(data, "Res")) then
     tmr.alarm(4, 200, 0, function()
        m:publish("/room/beamer/state", "used", 0, 0)
     end) 
    end
  end, 0)
end

tmr.alarm(1, 1000, 1, function() 
   if wifi.sta.getip()=="0.0.0.0" or wifi.sta.getip() == nil then
      --print("Connect AP, Waiting...") 
   else
      --print("Connected")
      --print( wifi.sta.getip() )
      startTelnetServer()
      configureMqttService()
      tmr.stop(1)
   end
end)

uart.setup(0,9600,8,0,1,0)
