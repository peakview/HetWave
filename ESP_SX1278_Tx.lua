
SX_MCU_init()

if SXread(0x42)==0x12 then
  SX1276_LoRa_Init()

  --function CCTxTest()
  if 1==1 then
    SXTxTimer = tmr.create()
    iiTx=1
    -- oo calling
    SXTxTimer:register(3000, tmr.ALARM_AUTO, 
    function (t) SXxmit("Its brightest stars are Rigel Beta Orionis + Betel-" .. iiTx .."\n"); iiTx=iiTx+1;  end)
    SXTxTimer:start()

    --SXTxTimer:unregister()
  end
else
  print("SXread(0x42)==0x12 fails")
end
