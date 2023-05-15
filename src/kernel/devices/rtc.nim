# Real-Time Clock
#
# This module uses the CMOS RTC to read the current date and time.
import std/strformat

import ports

type
  DateTime* = object
    year*: uint16
    month*, day*, hour*, minute*, second*: uint8

proc `$`*(dt: DateTime): string =
  return fmt"{dt.year}-{dt.month:02}-{dt.day:02} {dt.hour:02}:{dt.minute:02}:{dt.second:02} UTC"

proc readCMOS(reg: uint8): uint8 =
  portOut8(0x70, reg)
  return portIn8(0x71)

proc bcdToBinary(bcd: uint8): uint8 {.inline.} =
  return (bcd and 0x0F) + ((bcd and 0xF0) shr 3) + ((bcd and 0xF0) shr 1)

proc getDateTime*(): DateTime =
  result.year = readCMOS(0x09)
  result.month = readCMOS(0x08)
  result.day = readCMOS(0x07)
  result.hour = readCMOS(0x04)
  result.minute = readCMOS(0x02)
  result.second = readCMOS(0x00)

  # read registerB
  portOut8(0x70, 0x0B)
  var regB = portIn8(0x71)

  if (regB and 0x04) == 0:
    # BCD mode
    result.year = bcdToBinary(result.year.uint8).uint16 + 2000
    result.month = bcdToBinary(result.month)
    result.day = bcdToBinary(result.day)
    result.hour = bcdToBinary(result.hour)
    result.minute = bcdToBinary(result.minute)
    result.second = bcdToBinary(result.second)
  
  if (regB and 0x02) == 0:
    # 12 hour mode
    if (result.hour and 0x80) != 0:
      result.hour = (result.hour and 0x7F) + 12
