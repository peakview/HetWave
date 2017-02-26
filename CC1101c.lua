
if 1==1 then
for ii=1,3,1 do
CCxmit("Its brightest stars are Rigel Beta Orionis + Betel-" .. ii .."\n")
print(ii)
tmr.delay(600000)
end
end
--pinGDO0=11
--gpio.mode(,gpio.OUTPUT)
--print(gpio.read(pinGDO0))


for iiR=1,10 do
--CC1101_Clear_RxBuffer( );
--  CC1101_Set_Idle_Mode(); --Enter Idle mode to clear Rx buffer
--    CC1101_Write_Cmd( CC1101_SIDLE );
  CCwrite(0x36)
--  CC1101_Write_Cmd( CC1101_SFRX );  --Clear Rx buffer
  CCwrite(0x3A)
--CC1101_Set_Mode( RX_MODE );
--  CC1101_Write_Reg(CC1101_IOCFG0,0x46);
  CCwrite(0x02,0x46) --CC1101_IOCFG0
--  CC1101_Write_Cmd( CC1101_SRX );
  CCwrite(0x34 ) --CC1101_SRX, Enable Rx
  CCstatus=CCread( 0x3D )
        print(string.format("%02X",CCstatus))
        tmr.delay(1000000)
--i = CC1101_Rx_Packet( g_RF24L01RxBuffer ); --
--if 0 ~= i then
-- drv_uart_tx_bytes( g_RF24L01RxBuffer, i ); ---

--CC1101_Get_RxCounter( )
RX_Buffer_Status=CCread(0x3B)
RX_byte_num = bit.band(RX_Buffer_Status,0x7F)
print("RX_byte_num = " .. RX_byte_num)
if RX_byte_num>0 then
  RxPktLen=CCread(0x3F)
  if bit.band(CCread(0x07),0x03) ~= 0 then --CC1101_PKTCTRL1
    Addr=CCread(0x3F) --CC1101_RXFIFO
  end
  RxPktLen=RxPktLen-1

  CCreadMulti(0x3F,RX_byte_num)
end

end
