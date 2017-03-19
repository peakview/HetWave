
SX_MCU_init()

if SXread(0x42)==0x12 then
  SX1276_LoRa_Init()
  SX_RF_RECEIVE()

  --function CCTxTest()
  if 1==1 then
    SXRxTimer = tmr.create()
    iiRx=1
    -- oo calling
    SXRxTimer:register(3000, tmr.ALARM_AUTO, 
    function (rx)  SXcontent=SXrecv(); print("SXRxTimer [" .. iiRx .. "]\n" .. SXcontent .."\n"); iiRx=iiRx+1;  end)
    SXRxTimer:start()

    --SXRxTimer:unregister()
  end
else
  print("SXread(0x42)==0x12 fails")
end