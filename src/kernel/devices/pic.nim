import ports


const
  Pic1DataPort = 0x21
  Pic2DataPort = 0xA1

proc disable*() =
  # # mask all interrupts
  portOut8(Pic1DataPort, 0xff)
  portOut8(Pic2DataPort, 0xff)
