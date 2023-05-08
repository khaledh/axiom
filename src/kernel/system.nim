import devices/ports

proc shutdown*() {.inline.} =
  portOut16(0x604, 0x2000)
