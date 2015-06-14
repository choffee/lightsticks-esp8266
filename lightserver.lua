

-- Simple NodeMCU web server (done is a not so nodeie fashion :-)
--
-- Written by Scott Beasley 2015
-- Open and free to change and use. Enjoy.
--

-- Your Wifi connection data

config = require("config")
local LED_PIN = config.LED_PIN
local LED_COUNT = 2

local LEDS = {}

for count = 1, LED_COUNT, 1 do
    LEDS[count] = {}
    LEDS[count]["r"] = 0
    LEDS[count]["g"] = 0
    LEDS[count]["b"] = 0
end


local function get_colour_from_url(request)
    local led, colour
    local red, green, blue
    led, colour = string.match(request, "/led/(%d)/colour/(%w+)")

    if colour == "red" then
        red = 255
        green = 0
        blue = 0
    elseif colour == "blue" then
        red = 0
        green = 0
        blue = 255
    elseif colour == "green" then
        red = 0
        green = 255
        blue = 0
    else
        red = 100
        green = 100
        blue = 100
    end
    if led < LED_COUNT then
        LEDS[led]["r"] = red
        LEDS[led]["g"] = green
        LEDS[led]["b"] = blue

    end
end

local function show_leds()
    local light = ""
    for count = 1, LED_COUNT, 1 do
        led = LEDS[count]
        light = light + string.char(led["r"], led["g"], led["b"])
    end
    ws2812.writergb(LED_PIN, light)
end

local function connect (conn, data)
   local query_data, colour

   conn:on ("receive",
      function (cn, req_data)
         query_data = get_http_req (req_data)
         print (query_data["METHOD"] .. " " .. " " .. query_data["User-Agent"])
         print (query_data["REQUEST"])
         colour = get_colour_from_url(query_data["REQUEST"])
         cn:send("HTTP/1.1 200 OK\n")
         cn:send("Content-Type:text/html\n\n")
         cn:send("<h2>Control the lights</h2><p><table>")
         for led = 1, 2, 1 do
           cn:send(" <tr><td>Led " .. led .. "</td>")
           local colours = {"red", "green", "blue"}
           for colournum = 1 , #colours do
               col=colours[colournum]
             cn:send("<td><a href=\"/led/".. led .. "/colour/" .. col .. "\" style=\"color:".. col .. ";\">" .. col .. "<a/><td>")
           end
           cn:send("</tr>")
         end
         cn:send("</table>")
         -- Close the connection for the request
         cn:close ( )
      end)
end

function wait_for_wifi_conn ( )
   tmr.alarm (1, 1000, 1, function ( )
      if wifi.sta.getip ( ) == nil then
         print ("Waiting for Wifi connection")
      else
         tmr.stop (1)
         print ("ESP8266 mode is: " .. wifi.getmode ( ))
         print ("The module MAC address is: " .. wifi.ap.getmac ( ))
         print ("Config done, IP is " .. wifi.sta.getip ( ))
      end
   end)
end

-- Build and return a table of the http request data
function get_http_req (instr)
   local t = {}
   local first = nil
   local key, v, strt_ndx, end_ndx

   for str in string.gmatch (instr, "([^\n]+)") do
      -- First line in the method and path
      if (first == nil) then
         first = 1
         strt_ndx, end_ndx = string.find (str, "([^ ]+)")
         v = trim (string.sub (str, end_ndx + 2))
         key = trim (string.sub (str, strt_ndx, end_ndx))
         t["METHOD"] = key
         t["REQUEST"] = v
      else -- Process and reamaining ":" fields
         strt_ndx, end_ndx = string.find (str, "([^:]+)")
         if (end_ndx ~= nil) then
            v = trim (string.sub (str, end_ndx + 2))
            key = trim (string.sub (str, strt_ndx, end_ndx))
            t[key] = v
         end
      end
   end

   return t
end

-- String trim left and right
function trim (s)
  return (s:gsub ("^%s*(.-)%s*$", "%1"))
end

-- XXX This wants to be in a loop.
-- Configure the ESP as a station (client)
wifi.setmode (wifi.STATION)
wifi.sta.config (config.SSID, config.SSID_PASSWORD)
wifi.sta.autoconnect (1)

-- Hang out until we get a wifi connection before the httpd server is started.
wait_for_wifi_conn ( )

-- Create the httpd server
svr = net.createServer (net.TCP, 30)
ws2812.writergb(LED_PIN,string.char(50, 50, 50))

-- Server listening on port 80, call connect function if a request is received
svr:listen (80, connect)
