--function CCTxTest()
CCTxTimer = tmr.create()
iiTx=1
-- oo calling
CCTxTimer:register(2000, tmr.ALARM_AUTO, 
function (t) CCxmit("Its brightest stars are Rigel Beta Orionis + Betel-" .. iiTx .."\n"); iiTx=iiTx+1;  end)
CCTxTimer:start()

--CCTxTimer:unregister()
--end