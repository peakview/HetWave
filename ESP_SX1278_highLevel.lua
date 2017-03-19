
function SX_RF_RECEIVE()
    SX1276_Set_TXRX_Mode(RegOpMode_TXRX.STDBY)
    SXwrite(0x11,0x9F) --(REG_LR_IRQFLAGSMASK, IRQN_RXD_Value)
    SXwrite(0x24,0xFF) --(REG_LR_HOPPERIOD, PACKET_MIAX_Value);
    SXwrite(0x40,0x00) --( REG_LR_DIOMAPPING1, 0X00);
    SXwrite(0x41,0x00) --( REG_LR_DIOMAPPING2, 0X00);
    SX1276_Set_TXRX_Mode(RegOpMode_TXRX.RXC)
end


function SXxmit(Datas)
  local LEN=string.len(Datas)

  SX1276_Set_TXRX_Mode(RegOpMode_TXRX.STDBY)
  SXwrite(0x24, 0)    --REG_LR_HOPPERIOD, 0: no hopping
  SXwrite(0x11, 0xF7) --(REG_LR_IRQFLAGSMASK, IRQN_TXD_Value)
  SXwrite(0x22, LEN)  --REG_LR_PAYLOADLENGTH
  SXwrite(0x0E, 0) --REG_LR_FIFOTXBASEADDR
  SXwrite(0x0D, 0) --REG_LR_FIFOADDRPTR

  gpio.write(pin, gpio.LOW)
  CCstatus=spi.send(SPI_ID,0x80)
  print("SXwrite Reg[0x" .. string.format("%02X",0x3F) .. "]=SXnil" .. CCstatus)
    

  for ii=1,LEN do
      local Ntx,CCstatus=spi.send(SPI_ID,string.byte(Datas,ii))
      if bit.band(0x0F,CCstatus)~=0x0F then
        print("-SXlast=" .. string.format("%02X",CCstatus) .. ", tx" .. string.format("%02X",string.byte(Datas,ii)))
      end
  end
  gpio.write(pin, gpio.HIGH)
  tmr.delay(100)
  --lpTypefunc.lpSwitchEnStatus(enOpen);
  --lpTypefunc.lpByteWritefunc(0x80);
  --for (ASM_i = 0; ASM_i < LEN; ASM_i++) {
  --    lpTypefunc.lpByteWritefunc(*RF_TRAN_P);
  --    RF_TRAN_P++;
  --}
  --lpTypefunc.lpSwitchEnStatus(enClose);
    
  SXwrite(0x40, 0x40) --REG_LR_DIOMAPPING1
  SXwrite(0x41, 0x00) --REG_LR_DIOMAPPING2
  SX1276_Set_TXRX_Mode(RegOpMode_TXRX.TX)
end


--print(bit.rshift(0x3FF , 8))
function SX1276_LoRa_Init()
  SX1276_Set_TXRX_Mode(RegOpMode_TXRX.SLEEP )
  SX1276_Set_FskLora_Mode( RegOpMode_FskLora.LORA )
  SX1276_Set_TXRX_Mode( RegOpMode_TXRX.STDBY )
  SXwrite(0x40,0x00) --REG_LR_DIOMAPPING1
  SXwrite(0x41,0x00) --REG_LR_DIOMAPPING2
  
  --SX1276LoRaSetRFFrequency();  //Regs 0x06 - 0x0F
  SXwrite(0x06,0x6c,0x80,0x00)

  --SX1276LoRaSetRFPower(powerValue);
  ---SX1276WriteBuffer( REG_LR_PADAC, 0x87);
  SXwrite(0x4D,0x87)
  ---SX1276WriteBuffer( REG_LR_PACONFIG, power_data[power]);
  SXwrite(0x09,power_data[powerValue])

  SX1276LoRaSetSpreadingFactor(12) --SpreadingFactor
  SX1276LoRaSetErrorCoding(2)  --CodingRate 2: 4/6
  SX1276LoRaSetPacketCrcOn(1) --RxPayloadCrcOn 1:true
  SX1276LoRaSetSignalBandwidth(7)  -- Bw_Frequency 7:125kHz
  SX1276LoRaSetImplicitHeaderOn(0)  -- 0:Explicit Header Mode
  SX1276LoRaSetPayloadLength(0xff)
  SX1276LoRaSetSymbTimeout(0x3FF)
  SX1276LoRaSetMobileNode(1)

  SX_RF_RECEIVE()
  
  -- SX1276_WriteReg( REG_LR_IRQFLAGSMASK, 0xFF );  //Regs 0x11 ,
  --SXwrite(0x11,0xFF) --deactivate all IRQ
  -- SX1276_WriteBuffer( REG_LR_MODEMCONFIG1, RegsTable2, 0x24 - 0x1D + 1 );  //Regs 0x1D - 0x24
  --SWwrite(0x1D,)
--  SX1276_WriteReg( REG_LR_MODEMCONFIG3, DEF_LR_MODEMCONFIG3 );  //Regs 0x26, Low Data Rata Optimization Disabled
   -- SX1276_WriteReg( REG_LR_MODEMCONFIG3, 0x08 );  //Regs 0x26, Low Data Rata Optimization Enabled
   -- SX1276_WriteReg( REG_LR_DIOMAPPING1, DEF_LR_DIOMAPPING1 );  //Regs 0x40
   -- SX1276_WriteReg( REG_LR_DIOMAPPING2, DEF_LR_DIOMAPPING2 );  //Regs 0x41
   -- SX1276_WriteReg( REG_LR_PADAC, DEF_LR_PADAC | RFLR_PADAC_20DBM_ON );  //Regs 0x4D
   -- SX1276_WriteReg( 0x70, 0x10 );
end

function SX_MCU_init()
-- Init ESP8266 Pins
-- pin=8 as CSn, SPI port init
  spi.setup(SPI_ID,spi.MASTER,spi.CPOL_LOW,spi.CPHA_LOW,spi.DATABITS_8,128,spi.FULLDUPLEX)
  gpio.mode(pin, gpio.OUTPUT)

  gpio.mode(pinReset, gpio.OUTPUT)
  status = SXreset()
  print('SX_MCU_init(): (if ==0 fails)' .. status)
end

SX_MCU_init()
SX1276_LoRa_Init()

--function CCTxTest()
if 1==0 then
SXTxTimer = tmr.create()
iiTx=1
-- oo calling
SXTxTimer:register(3000, tmr.ALARM_AUTO, 
function (t) SXxmit("Its brightest stars are Rigel Beta Orionis + Betel-" .. iiTx .."\n"); iiTx=iiTx+1;  end)
SXTxTimer:start()

--SXTxTimer:unregister()
end
--