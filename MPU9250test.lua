--via SPI

pinNCS=8 --CSn, D8
SPI_ID=1  --HSPI

function MPUwrite(Addr, ...)
  gpio.write(pinNCS, gpio.LOW) --CSn
  --if table.getn(arg)>1 then
  --  Addr=bit.bor(0x40,Addr) --Set Burst bit=1
  --end
  Ntx,CCstatus=spi.send(SPI_ID,Addr)
  --print("CCwrite Reg[0x" .. string.format("%02X",Addr) .. "]=CCstatus" .. string.format("%02X",CCstatus))

  for i,v in ipairs(arg) do
    local Ntx,CCstatus=spi.send(SPI_ID,v)
    --print("-CCstatus=" .. string.format("%02X",CCstatus) .. ", +" .. string.format("%02X",v))
  end
  gpio.write(pinNCS, gpio.HIGH) --CS
  tmr.delay(20)
  return CCstatus
end

-- Read SX1278 Reg
function MPUread(Addr,Verbose)
  Verbose=Verbose or 0
  gpio.write(pinNCS, gpio.LOW)
  --local Ntx,CCstatus=spi.send(SPI_ID,bit.bor(0x80,Addr))
  local Ntx,CCstatus=spi.send(SPI_ID,bit.bor(0x80,Addr))
  local read = spi.recv(SPI_ID, 1)
  local readbyte = string.byte(read)
  if Verbose==1 then
    print("SXread Reg[0x" .. string.format("%02X",Addr) .. "]=0x" .. string.format("%02X",readbyte) .. ", CCstatus num=" .. string.format("%02X",CCstatus))
  end
  gpio.write(pinNCS, gpio.HIGH)
  --tmr.delay(20)
return readbyte,CCstatus
end

-- Read CC1101 Reg Burst
function MPUreadMulti(Addr,Len,Verbose)
  Verbose=Verbose or 0
  gpio.write(pinNCS, gpio.LOW)
  local Ntx,CCstatus=spi.send(SPI_ID,bit.bor(0x80,Addr))
  local read = 1
  local readbyte = 1
  local reads=""
  for ii=1,Len do
    read = spi.recv(SPI_ID, 1)
    readbyte = string.byte(read)
    reads=reads .. read
    if Verbose==1 then
      print("MPUread Reg[0x" .. string.format("%02X",Addr) .. "]=0x" .. string.format("%02X",readbyte) .. "," .. string.format("%c",readbyte) .. ", CCstatus num=" .. string.format("%02X",CCstatus))
      Addr=Addr+1
    end
  end
  gpio.write(pinNCS, gpio.HIGH)
  tmr.delay(20)
return reads,CCstatus
end


function MPUinit()
PWR_MGMT_1=0x6B
MPUwrite(PWR_MGMT_1,0x80) --Reset Device
tmr.delay(1000)
MPUwrite(0x6A,0x02) --MPUREG_USER_CTRL:I2C_MST_RST
--Single_Write(GYRO_ADDRESS,PWR_MGMT_1, 0x00);    //解除休眠状态
MPUwrite(PWR_MGMT_1,0x01) --Clock Source
--Single_Write(GYRO_ADDRESS,SMPLRT_DIV, 0x07);
SMPLRT_DIV=0x19
MPUwrite(SMPLRT_DIV,0x07)
--Single_Write(GYRO_ADDRESS,CONFIG, 0x06);
CONFIG=0x1A
MPUwrite(CONFIG,0x06)
--Single_Write(GYRO_ADDRESS,GYRO_CONFIG, 0x18);
GYRO_CONFIG=0x1B
MPUwrite(GYRO_CONFIG,0x18)
--Single_Write(GYRO_ADDRESS,ACCEL_CONFIG, 0x01);
ACCEL_CONFIG=0x1C
MPUwrite(ACCEL_CONFIG,0x01)


MPUwrite(0x6A,0x20) --MPUREG_USER_CTRL
MPUwrite(0x24,0x0D) --MPUREG_I2C_MST_CTRL
MPUwrite(0x25,0x0C) --MPUREG_I2C_SLV0_ADDR,AK8963_I2C_ADDR

--{AK8963_CNTL2, MPUREG_I2C_SLV0_REG}, //I2C slave 0 register address from where to begin data transfer
MPUwrite(0x26,0x0B)
--{0x01, MPUREG_I2C_SLV0_DO}, // Reset AK8963
MPUwrite(0x63,0x01)
--{0x81, MPUREG_I2C_SLV0_CTRL},  //Enable I2C and set 1 byte
MPUwrite(0x27,0x81)

--{AK8963_CNTL1, MPUREG_I2C_SLV0_REG}, //I2C slave 0 register address from where to begin data transfer
MPUwrite(0x26,0x0A)
--{0x12, MPUREG_I2C_SLV0_DO}, // Register value to continuous measurement in 16bit
MPUwrite(0x63,0x12)
--{0x81, MPUREG_I2C_SLV0_CTRL}  //Enable I2C and set 1 byte
MPUwrite(0x27,0x81)

MPUwrite(0x25,0x8C)
MPUwrite(0x26,0x00) --AK8963_WIA
MPUwrite(0x27,0x81)
WIA = MPUread(0x49,1)
if WIA ~=0x48 then
print("MPUInit Error:" .. string.format("%02X",WIA))
end
end



  spi.setup(SPI_ID,spi.MASTER,spi.CPOL_LOW,spi.CPHA_LOW,spi.DATABITS_8,128,spi.FULLDUPLEX)
  gpio.mode(pinNCS, gpio.OUTPUT)

--Check SPI interface read 
WIA = MPUread(0x75,1)
if WIA~=0x71 then
print("MPU9250 init error:" string.format("%02X",WIA))
end
MPUread(0x6B,1)
MPUread(0x6C,1)
MPUinit()
for ii=1,20 do
ACCEL_XOUT_H=MPUread(0x3B,0)
ACCEL_XOUT_L=MPUread(0x3C,0)
print(ACCEL_XOUT_H,ACCEL_XOUT_L)
--
--MPUread(0x3D,1)
--MPUread(0x3E,1)
tmr.delay(100000)
end

for ii=1,20 do
GYRO_XOUT_H=MPUread(0x43,0)
GYRO_XOUT_L=MPUread(0x44,0)
GYRO_YOUT_H=MPUread(0x45,0)
GYRO_YOUT_L=MPUread(0x46,0)
GYRO_ZOUT_H=MPUread(0x47,0)
GYRO_ZOUT_L=MPUread(0x48,0)
--print(GYRO_XOUT_H,GYRO_XOUT_L,GYRO_YOUT_H,GYRO_YOUT_L,GYRO_ZOUT_H,GYRO_ZOUT_L)
print(GYRO_XOUT_H,GYRO_YOUT_H,GYRO_ZOUT_H)
--
--MPUread(0x3D,1)
--MPUread(0x3E,1)
tmr.delay(100000)
end

for ii=1,5 do

--Send I2C command at first
--WriteReg(MPUREG_I2C_SLV0_ADDR,AK8963_I2C_ADDR|READ_FLAG); //Set the I2C slave addres of AK8963 and set for read.
MPUwrite(0x25,0x8C)
--WriteReg(MPUREG_I2C_SLV0_REG, AK8963_HXL); //I2C slave 0 register address from where to begin data transfer
MPUwrite(0x26,0x03)
--WriteReg(MPUREG_I2C_SLV0_CTRL, 0x87); //Read 7 bytes from the magnetometer
MPUwrite(0x27,0x87)

reads=MPUreadMulti(0x3B,21,1)


--print(GYRO_XOUT_H,GYRO_XOUT_L,GYRO_YOUT_H,GYRO_YOUT_L,GYRO_ZOUT_H,GYRO_ZOUT_L)
--print(string.format("%c",reads[14]),string.format("%c",reads[15]),string.format("%c",reads[16]))
--
--MPUread(0x3D,1)
--MPUread(0x3E,1)
tmr.delay(100000)
end
print(reads)
