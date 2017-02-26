if 1==0 then  --change to if true
	print("set up wifi mode")
	--wifi.setmode(wifi.STATION)
	--please config ssid and password according to settings of your wireless router.
	--wifi.sta.config("Rational","eastlake")
	--wifi.sta.connect()
    --myip=wifi.sta.getip()
    --print(myip)
	cnt = 0
	tmr.alarm(1, 1000, 1, function() 
	    if (wifi.sta.getip() == nil) and (cnt < 20) then 
	    	print("IP unavaiable, Waiting...")
	    	cnt = cnt + 1 
	    else 
	    	tmr.stop(1)
	    	if (cnt < 20) then print("Config done, IP is "..wifi.sta.getip())
	    	--dofile("yourfile.lua")
	    	else print("Wifi setup time more than 20s, Please verify wifi.sta.config() function. Then re-download the file.")
	    	end
	    end 
	 end)
else
  print("\n")
  print("\n")
  print("\n")
  --dofile("httpTrigger.lua")
  print("ESP_CC1101 Tx Test")
  dofile("ESP_CC1101_association.lua")
  dofile("CC1101c.lua")
end
