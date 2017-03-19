-- C2102 EVM broad:SPI1
pin=8 --CSn, D8
SPI_ID=1  --HSPI
pinReset=1

RegOpMode_FskLora={
  FSK_OOK = 0x00,
  LORA = 0x80
}
RegOpMode_TXRX={
  SLEEP =   0x00,
  STDBY =   0x01,
  FSTX  =   0x02,
  TX    =   0x03,
  FSRX  =   0x04,
  RXC   =   0x05,
  RXS   =   0x06,
  CAD   =   0x07,
}
power_data = { 0X80, 0X80, 0X80, 0X83, 0X86, 0x89, 0x8c, 0x8f }
powerValue = 7
--print(power_data[powerValue])
--print(LORA_CHIP_MODE.CAD)
--pinGDO2=2
--print(RegOpMode_TXRX[4])

-- Set CC1101 Reg
function SXwrite(Addr, ...)
  gpio.write(pin, gpio.LOW) --CSn
  --if table.getn(arg)>1 then
  --  Addr=bit.bor(0x40,Addr) --Set Burst bit=1
  --end
  Ntx,CCstatus=spi.send(SPI_ID,bit.bor(0x80,Addr))
  --print("CCwrite Reg[0x" .. string.format("%02X",Addr) .. "]=CCstatus" .. string.format("%02X",CCstatus))

  for i,v in ipairs(arg) do
    local Ntx,CCstatus=spi.send(SPI_ID,v)
    --print("-CCstatus=" .. string.format("%02X",CCstatus) .. ", +" .. string.format("%02X",v))
  end
  gpio.write(pin, gpio.HIGH) --CS
  tmr.delay(20)
  return CCstatus
end

-- Read SX1278 Reg
function SXread(Addr,Verbose)
  Verbose=Verbose or 0
  gpio.write(pin, gpio.LOW)
  --local Ntx,CCstatus=spi.send(SPI_ID,bit.bor(0x80,Addr))
  local Ntx,CCstatus=spi.send(SPI_ID,Addr)
  local read = spi.recv(SPI_ID, 1)
  local readbyte = string.byte(read)
  if Verbose==1 then
    print("SXread Reg[0x" .. string.format("%02X",Addr) .. "]=0x" .. string.format("%02X",readbyte) .. ", CCstatus num=" .. string.format("%02X",CCstatus))
  end
  gpio.write(pin, gpio.HIGH)
  --tmr.delay(20)
return readbyte,CCstatus
end

-- Read CC1101 Reg Burst
function SXreadMulti(Addr,Len,Verbose)
  Verbose=Verbose or 0
  gpio.write(pin, gpio.LOW)
  local Ntx,CCstatus=spi.send(SPI_ID,Addr)
  local read = 1
  local readbyte = 1
  local reads=""
  for ii=1,Len do
    read = spi.recv(SPI_ID, 1)
    readbyte = string.byte(read)
    reads=reads .. read
    if Verbose==1 then
      print("SXread Reg[0x" .. string.format("%02X",Addr) .. "]=0x" .. string.format("%02X",readbyte) .. "," .. string.format("%c",readbyte) .. ", CCstatus num=" .. string.format("%02X",CCstatus))
    end
  end
  gpio.write(pin, gpio.HIGH)
  tmr.delay(20)
return reads,CCstatus
end

function SXreset()
  gpio.write(pinReset, gpio.LOW)
  tmr.delay(2000) --1ms
  gpio.write(pinReset, gpio.HIGH)
  tmr.delay(8000) --6ms

  SXread(0x42,1) --Check Chip Version
  local REG_OPMODE = SXread(0x01,1)
  for ii=1,100 do
    SXwrite(0x01, 0x08, 1)
    RegOpMode = SXread(0x01,1)  --Check Mode Write
    if RegOpMode == 0x08 then
      return ii
    end
  end
  return 0
end


function SX1276_Set_TXRX_Mode( TXRX_mode )
  local RegOpMode = bit.band(SXread(0x01),0xF8)
  SXwrite(0x01,bit.bor(RegOpMode, TXRX_mode))
end
function SX1276_Set_FskLora_Mode( FSKLORA_MODE )
  local RegOpMode = bit.band(SXread(0x01),0x80)
  SXwrite(0x01,bit.bor(RegOpMode, FSKLORA_MODE))
end


function SX1276LoRaSetSpreadingFactor(SpreadingFactor)
  ---SX1276LoRaSetNbTrigPeaks(3);
  local RegDetectOptimize = SXread(0x31)
  if SpreadingFactor>6 then
    SXwrite(0x31, bit.bor(bit.band(RegDetectOptimize,0xF8),0x03))  --0x03 is for SF7 to SF12; 0x05 is for SF6
  else
    SXwrite(0x31, bit.bor(bit.band(RegDetectOptimize,0xF8),0x05))  --0x03 is for SF7 to SF12; 0x05 is for SF6
  end
  ---RECVER_DAT = SX1276ReadBuffer( REG_LR_MODEMCONFIG2);
  local RegModemConfig2=SXread(0x1E)
  ---RECVER_DAT = (RECVER_DAT & RFLR_MODEMCONFIG2_SF_MASK) | (factor << 4);
  RegModemConfig2=bit.bor( bit.band(RegModemConfig2,0x0F), bit.lshift(SpreadingFactor,4))
  ---SX1276WriteBuffer( REG_LR_MODEMCONFIG2, RECVER_DAT)
  SXwrite(0x1E,RegModemConfig2)
end

function  SX1276LoRaSetErrorCoding(CodingRate)
  local RegModemConfig1 = SXread(0x1D)
  RegModemConfig1 = bit.bor(bit.band(RegModemConfig1, 0xF1),
    bit.lshift(CodingRate, 1)) --CodingRate bit 3:1
  SXwrite( 0x1D, RegModemConfig1)
end

function SX1276LoRaSetPacketCrcOn(RxPayloadCrcOn) 
  --RegModemConfig2 bit 2: RxPayloadCrcOn
  local RegModemConfig2 = SXread( 0x1E)
  --RegModemConfig2 = (RegModemConfig2 & RFLR_MODEMCONFIG2_RXPAYLOADCRC_MASK)| (enable << 2);
  RegModemConfig2=bit.bor( bit.band(RegModemConfig2,0xFB), bit.lshift(RxPayloadCrcOn,2))
  SXwrite(0x1E,RegModemConfig2)
end


function SX1276LoRaSetSignalBandwidth(bw)
  local RegModemConfig1 = SXread(0x1D)
  RegModemConfig1 = bit.bor(bit.band(RegModemConfig1, 0x0F), 
    bit.lshift(bw, 4))
  SXwrite(0x1D, RegModemConfig1)
end

function SX1276LoRaSetImplicitHeaderOn(ImplicitHeaderOn)
  local RegModemConfig1 = SXread(0x1D)
  RegModemConfig1 = bit.bor(bit.band(RegModemConfig1, 0xFE),ImplicitHeaderOn)
  SXwrite(0x1D, RegModemConfig1)
end

function SX1276LoRaSetPayloadLength(PayloadLength)
  SXwrite(0x22, PayloadLength)
end


function SX1276LoRaSetSymbTimeout(value) 
  local RegModemConfig2 = SXread(0x1E)
  local SYMBTIMEOUTLSB = SXread(0x1F)
  RegModemConfig2 = bit.bor(bit.band(RegModemConfig2, 0xFC),
    bit.rshift(value , 8))
  SYMBTIMEOUTLSB = bit.band(value, 0xFF)
  SXwrite(0x1E, RegModemConfig2)
  SXwrite(0x1F, SYMBTIMEOUTLSB)
end

function SX1276LoRaSetMobileNode(val)
  local RegModemConfig3 = SXread( 0x26)
  RegModemConfig3 = bit.bor(bit.band(RegModemConfig3, 0xF7),
    bit.lshift(val, 3))
  SXwrite(0x26, RegModemConfig3) --REG_LR_MODEMCONFIG3
end
