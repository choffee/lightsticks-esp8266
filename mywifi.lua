-- Your Wifi connection data

local config = require("config")

local ledon = true

function wait_for_wifi_conn ( )
   tmr.alarm (1, 500, 1, function ( )
      if wifi.sta.getip ( ) == nil then
         print ("Waiting for Wifi connection")
         if ledon then
             ws2812.writergb(config.LED_PIN, string.char(100,0,0))
             ledon = false
         else
             ws2812.writergb(config.LED_PIN, string.char(0,0,0))
             ledon = true
         end
      else
         tmr.stop (1)
         print ("ESP8266 mode is: " .. wifi.getmode ( ))
         print ("The module MAC address is: " .. wifi.ap.getmac ( ))
         print ("Config done, IP is " .. wifi.sta.getip ( ))
         ws2812.writergb(config.LED_PIN, string.char(0,100,0))
      end
   end)
end


-- XXX This wants to be in a loop.
-- Configure the ESP as a station (client)
wifi.setmode (wifi.STATION)
wifi.sta.config (config.SSID, config.SSID_PASSWORD)
wifi.sta.autoconnect (1)

-- Hang out until we get a wifi connection before the httpd server is started.
wait_for_wifi_conn ( )

