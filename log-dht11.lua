-- Measure temperature and humidity.
-- This time, for real.
-- Code adapted from https://github.com/ok1cdj/ESP8266-LUA

sensorPrefix = "TEST1_" .. node.chipid() .. "_"

dht11_pin = 5

Humidity = 0
HumidityDec=0
Temperature = 0
TemperatureDec=0
Checksum = 0
ChecksumTest=0

function getTemp()
   Humidity = 0
   HumidityDec=0
   Temperature = 0
   TemperatureDec=0
   Checksum = 0
   ChecksumTest=0

   --Data stream acquisition timing is critical. There's
   --barely enough speed to work with to make this happen.
   --Pre-allocate vars used in loop.

   bitStream = {}
   for j = 1, 40, 1 do
      bitStream[j]=0
   end
   bitlength=0

   gpio.mode(dht11_pin, gpio.OUTPUT)
   gpio.write(dht11_pin, gpio.LOW)
   tmr.delay(20000)
   --Use Markus Gritsch trick to speed up read/write on GPIO
   gpio_read=gpio.read
   gpio_write=gpio.write

   gpio.mode(dht11_pin, gpio.INPUT)

   --bus will always let up eventually, don't bother with timeout
   while (gpio_read(dht11_pin)==0 ) do end

   c=0
   while (gpio_read(dht11_pin)==1 and c<100) do c=c+1 end

   --bus will always let up eventually, don't bother with timeout
   while (gpio_read(dht11_pin)==0 ) do end

   c=0
   while (gpio_read(dht11_pin)==1 and c<100) do c=c+1 end

   --acquisition loop
   for j = 1, 40, 1 do
      while (gpio_read(dht11_pin)==1 and bitlength<10 ) do
         bitlength=bitlength+1
      end
      bitStream[j]=bitlength
      bitlength=0
      --bus will always let up eventually, don't bother with timeout
      while (gpio_read(dht11_pin)==0) do end
   end

   --DHT data acquired, process.

   for i = 1, 8, 1 do
      if (bitStream[i+0] > 2) then
         Humidity = Humidity+2^(8-i)
      end
   end
   for i = 1, 8, 1 do
      if (bitStream[i+8] > 2) then
         HumidityDec = HumidityDec+2^(8-i)
      end
   end
   for i = 1, 8, 1 do
      if (bitStream[i+16] > 2) then
         Temperature = Temperature+2^(8-i)
      end
   end
   for i = 1, 8, 1 do
      if (bitStream[i+24] > 2) then
         TemperatureDec = TemperatureDec+2^(8-i)
      end
   end
   for i = 1, 8, 1 do
      if (bitStream[i+32] > 2) then
         Checksum = Checksum+2^(8-i)
      end
   end

   ChecksumTest=(Humidity+HumidityDec+Temperature+TemperatureDec) % 0xFF

   --TODO verify checksum.

   print ("Temperature: "..Temperature.."."..TemperatureDec)
   print ("Humidity: "..Humidity.."."..HumidityDec)
   print ("ChecksumReceived: "..Checksum)
   print ("ChecksumTest: "..ChecksumTest)
end

function sendTempHumData()
   getTemp()
   -- send temperature
   print("Sending temperature...")
   data = "value=" .. Temperature.."."..TemperatureDec
   conn=net.createConnection(net.TCP, 0)
   conn:on("receive", function(conn, payload) print(payload) end)
   conn:connect(8192,'192.168.1.123')
   conn:send("POST /sensors/remote-value/" .. sensorPrefix .. "TEST_TEMP HTTP/1.1\r\n")
   conn:send("Host: 192.168.1.123\r\n") 
   conn:send("Accept: */*\r\n") 
   conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n") -- FIXME replace
   conn:send("Content-Length: " .. string.len(data) .. "\r\n")
   conn:send("Content-Type: application/x-www-form-urlencoded\r\n")
   conn:send("\r\n")
   conn:send(data)
   conn:on("sent",function(conn)
              print("Closing connection")
              conn:close()
   end)
   conn:on("disconnection", function(conn)
              print("Got disconnection...")
   end)

   -- send humidity
   print("Sending humidity...")
   data = "value=" .. Humidity ..".".. HumidityDec
   conn=net.createConnection(net.TCP, 0)
   conn:on("receive", function(conn, payload) print(payload) end)
   conn:connect(8192,'192.168.1.123') 
   conn:send("POST /sensors/remote-value/" .. sensorPrefix .. "TEST_HUM HTTP/1.1\r\n")
   conn:send("Host: 192.168.1.123\r\n") 
   conn:send("Accept: */*\r\n") 
   conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n") -- FIXME replace
   conn:send("Content-Length: " .. string.len(data) .. "\r\n")
   conn:send("Content-Type: application/x-www-form-urlencoded\r\n")
   conn:send("\r\n")
   conn:send(data)
   conn:on("sent",function(conn)
              print("Closing connection")
              conn:close()
   end)
   conn:on("disconnection", function(conn)
              print("Got disconnection...")
   end)
end

tmr.alarm(2, 60000, 1, function() sendTempHumData() end)
