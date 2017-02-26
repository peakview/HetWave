if 1==0 then
-- CH340 EVM broad:SPI0, can't work. consider SPI 1
pin=6 --CSn, GPIO16, D0
SPI_ID=0 --SPI
pinGDO0=12 --GPIO10
else
-- C2102 EVM broad:SPI1
pin=8 --CSn, D8
SPI_ID=1  --HSPI
pinGDO0=1 
end

pinGDO2=2

-- Set CC1101 Reg
function CCwrite(Addr, ...)
  gpio.write(pin, gpio.LOW) --CSn
  if table.getn(arg)>1 then
    Addr=bit.bor(0x40,Addr) --Set Burst bit=1
  end
  Ntx,CCstatus=spi.send(SPI_ID,Addr)
  --print("CCwrite Reg[0x" .. string.format("%02X",Addr) .. "]=CCstatus" .. string.format("%02X",CCstatus))

  for i,v in ipairs(arg) do
    local Ntx,CCstatus=spi.send(SPI_ID,v)
    --print("-CCstatus=" .. string.format("%02X",CCstatus) .. ", +" .. string.format("%02X",v))
  end
  gpio.write(pin, gpio.HIGH) --CS
  tmr.delay(20)
  return CCstatus
end

-- Read CC1101 Reg
function CCread(Addr)
  gpio.write(pin, gpio.LOW)
  local Ntx,CCstatus=spi.send(SPI_ID,bit.bor(0x80,Addr))
  local read = spi.recv(SPI_ID, 1)
  local readbyte = string.byte(read)
  print("CCread Reg[0x" .. string.format("%02X",Addr) .. "]=0x" .. string.format("%02X",readbyte) .. ", CCstatus num=" .. string.format("%02X",CCstatus))
  gpio.write(pin, gpio.HIGH)
  tmr.delay(20)
return readbyte,CCstatus
end

-- Read CC1101 Reg Burst
function CCreadMulti(Addr,Len,Verbose)
  Verbose=Verbose or 0
  gpio.write(pin, gpio.LOW)
  local Ntx,CCstatus=spi.send(SPI_ID,bit.bor(0xC0,Addr))
  local read = 1
  local readbyte = 1
  local reads=""
  for ii=1,Len do
    read = spi.recv(SPI_ID, 1)
    readbyte = string.byte(read)
    reads=reads .. read
    if Verbose==0 then
      print("CCread Reg[0x" .. string.format("%02X",Addr) .. "]=0x" .. string.format("%02X",readbyte) .. "," .. string.format("%c",readbyte) .. ", CCstatus num=" .. string.format("%02X",CCstatus))
    end
  end
  gpio.write(pin, gpio.HIGH)
  tmr.delay(20)
return reads,CCstatus
end

--set CCaddress as CC1101 MAC address, set BroadcastMode as 
function CCsetAddress(CCaddress,BroadcastMode)
  BroadcastMode = BroadcastMode or 0x03
  CCstatus,btmp=CCread(0x07) --CC1101_PKTCTRL1
  CCwrite(0x09, CCaddress) --CC1101_ADDR
  local btmp=bit.band(btmp,0xFC)
  CCwrite(0x07,bit.bor(btmp,BroadcastMode))
  print("CCread: STA.Addr=".. string.format("%02X",CCread(0x09)) .. ",CC1101_PKTCTRL1=" .. string.format("%02X",CCread(0x07)))
end




function CCinit()


-- Reset CC1101
gpio.write(pin, gpio.HIGH)
tmr.delay(30)
gpio.write(pin, gpio.LOW)
tmr.delay(30)
gpio.write(pin, gpio.HIGH)
tmr.delay(45) 

gpio.write(pin, gpio.LOW)
CCstatus=spi.send(SPI_ID,0x30)
print("Reset CC1101, CCstatus num=" .. CCstatus)
gpio.write(pin, gpio.HIGH)
tmr.delay(100)

--CCwrite(0x09,0x5A)
--CCstatus,readbyte=CCread(0x09)
--print(string.format("0x%2X",readbyte))

--CC1101 Config
CCwrite(0x02, 0x06) --CC1101_IOCFG0:GDO0 output pin config, recommended to disable the clock output in initialization
CCwrite(0x03, 0x47) --CC1101_FIFOTHR:RX FIFO and TX FIFO thresholds
CCwrite(0x08, 0x05) --CC1101_PKTCTRL0:Packet automation control
CCwrite(0x0A, 0x96) --CC1101_CHANNR:Channel number
CCwrite(0x0B, 0x06) --CC1101_FSCTRL1:Frequency synthesizer control
CCwrite(0x0D, 0x0F) --CC1101_FREQ2:Frequency control word, high INT8U
CCwrite(0x0E, 0x62) --CC1101_FREQ1:Frequency control word, middle INT8U
CCwrite(0x0F, 0x76) --CC1101_FREQ0:Frequency control word, low INT8U
CCwrite(0x10, 0xF6) --CC1101_MDMCFG4:Modem configuration
CCwrite(0x11, 0x43) --CC1101_MDMCFG3:Modem configuration
CCwrite(0x12, 0x13) --CC1101_MDMCFG2:Modem configuration
CCwrite(0x15, 0x15) --CC1101_DEVIATN:
CCwrite(0x18, 0x18) --CC1101_MCSM0:Main Radio Control State Machine configuration, Automatically calibrate, ripple counter must expire after XOSC has stabilized
CCwrite(0x19, 0x16) --CC1101_FOCCFG:Frequency Offset Compensation configuration
CCwrite(0x20, 0xFB) --CC1101_WORCTRL:Wake On Radio control
CCwrite(0x23, 0xE9) --CC1101_FSCAL3:Frequency synthesizer calibration
CCwrite(0x24, 0x2A) --CC1101_FSCAL2
CCwrite(0x25, 0x00) --CC1101_FSCAL1
CCwrite(0x26, 0x1F) --CC1101_FSCAL0
CCwrite(0x2C, 0x81) --CC1101_TEST2:Various test settings
CCwrite(0x2D, 0x35) --CC1101_TEST1
CCwrite(0x17, 0x3B) --CC1101_MCSM1:Main Radio Control State Machine configuration

CCsetAddress(0x05,0x03)

--Set Sync word 0x8799
CCwrite(0x04, 0x87) --CC1101_SYNC1
CCwrite(0x05, 0x99) --CC1101_SYNC0

--Modem Config
CCwrite(0x13, 0x72) --CC1101_MDMCFG1, FEC_EN:1bit, NUM_PREAMBLE:3bit, Reserved:2bit, CHANSPC_E:2bit

--PA Tables
CCwrite(0x3E, 0xc0, 0xC8, 0x84, 0x60, 0x68, 0x34, 0x1D, 0x0E)
end



function CCxmit(Datas)
    local TxSize=string.len(Datas)
    local l_RxWaitTimeout = 0;
    local Address = CCread(0x09)
    --CC1101_Clear_TxBuffer( ) = 
    -- step1. CC1101_Set_Idle_Mode( );
    -- -- CC1101_Write_Cmd( CC1101_SIDLE )
    CCwrite(0x36)
    -- step2. CC1101_Write_Cmd( CC1101_SFTX );
    CCwrite(0x3B)
    
    if bit.band(CCread(0x07),0x03)~=0 then
        CCwrite(0x3F, TxSize+1 ) --CC1101_TXFIFO
        CCwrite(0x3F, Address ) -- CC1101_TXFIFO, TxSize include Address 1byte
    else
        CCwrite(0x3F, TxSize+1 ) --CC1101_TXFIFO 
    end

    --CCwrite(0x3F, pTxBuff, TxSize )
    gpio.write(pin, gpio.LOW)
    if TxSize==1 then
      CCstatus=spi.send(SPI_ID,0x3F)
      print("CCwrite Reg[0x" .. string.format("%02X",0x3F) .. "]=CCstatus" .. CCstatus)
    else
      CCstatus=spi.send(SPI_ID,0x7F)
      print("CCwrite Reg[0x" .. string.format("%02X",0x7F) .. "]=CCstatus" .. CCstatus)
    end

    for ii=1,TxSize do
      local Ntx,CCstatus=spi.send(SPI_ID,string.byte(Datas,ii))
      if bit.band(0x0F,CCstatus)~=0x0F then
        print("-CCstatus=" .. string.format("%02X",CCstatus) .. ", tx" .. string.format("%02X",string.byte(Datas,ii)))
      end
    end
    gpio.write(pin, gpio.HIGH)
    tmr.delay(100)

  
    --CC1101_Set_Mode( TX_MODE );
    CCstatus=CCwrite( 0x02,0x46 ); --CC1101_IOCFG0, recover clock
    print("-CCstatus=" .. CCstatus .. ", tx")
    CCstatus=CCwrite( 0x35 ); --CC1101_STX
    print("-CCstatus=" .. CCstatus .. ", tx")
    --CC1101_GET_GDO0_STATUS( )
  --if 0==1 then
    print("w1")
    l_RxWaitTimeout = 0;
    while 0 ~= gpio.read(pinGDO0) do
      --print("pinGDO0" .. gpio.read(pinGDO0))
      l_RxWaitTimeout=l_RxWaitTimeout+1
      --Address,CCstatus = CCread(0x09)
      if 1==1 then -- if GDO 0 pin is connected
      CCstatus=CCwrite( 0x3D )
      print(string.format("%02X",CCstatus))
      if bit.band(CCstatus,0x1F)==0x1F then
        return
      end
      end
      --if bit.band(CCstatus,0x80)==0x00 then
      --  break
      --end
      if 10000 == l_RxWaitTimeout then
            l_RxWaitTimeout = 0
            --CCinit()
            print("w1: fails, timeout: Please Check physical pinGDO0")
            return
      end
    end
    --CC1101_GET_GDO0_STATUS( )
    print("w2")
    l_RxWaitTimeout = 0;
    while 0 == gpio.read(pinGDO0) do
     -- wait TX done
        
        --print("pinGDO0" .. gpio.read(pinGDO0))
        if 1==1 then
        CCstatus=CCwrite( 0x3D )
        print(string.format("%02X",CCstatus))
        if CCstatus==0x1F then
          break
        end
        end
        l_RxWaitTimeout=l_RxWaitTimeout+1
        tmr.delay(1000);
        if 1000 == l_RxWaitTimeout then
            l_RxWaitTimeout = 0
            --CCinit()
            print("w2: fails, timeout")
            break
        end
    end
  --end
end

-- Init ESP8266 Pins
-- pin=8 as CSn, SPI port init
spi.setup(SPI_ID,spi.MASTER,spi.CPOL_LOW,spi.CPHA_LOW,spi.DATABITS_8,16,spi.FULLDUPLEX)
--spi.setup(0,spi.MASTER,spi.CPOL_LOW,spi.CPHA_LOW,spi.DATABITS_8,0)
gpio.mode(pin, gpio.OUTPUT)

--GPIO_Init( CC1101_GDO0_GPIO_PORT, CC1101_GDO0_GPIO_PIN, GPIO_Mode_In_PU_No_IT  )
--GPIO_Init( CC1101_GDO2_GPIO_PORT, CC1101_GDO2_GPIO_PIN, GPIO_Mode_In_PU_No_IT  )
--gpio.mode(pinGDO0, gpio.INPUT, gpio.PULLUP)
gpio.mode(pinGDO0, gpio.INPUT)
gpio.mode(pinGDO2, gpio.INPUT, gpio.PULLUP)

CCinit()
tmr.delay(500)
