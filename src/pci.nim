import std/strformat

import cpu
import debug

proc pciConfigRead32*(bus, dev, fn, offset: uint8): uint32 =
  assert offset mod 4 == 0

  let address: uint32 =
    (1.uint32 shl 31) or
    (bus.uint32 shl 16) or
    (dev.uint32 shl 11) or
    (fn.uint32 shl 8) or
    offset

  portOut32(0xcf8'u16, address)
  result = portIn32(0xcfc)

proc addrOf(bus, dev, fn, offset: uint8): uint32 =
  result = (1.uint32 shl 31) or
    (bus.uint32 shl 16) or
    (dev.uint32 shl 11) or
    (fn.uint32 shl 8) or
    (offset and not 0b11'u8)

proc pciConfigRead16*(bus, dev, fn, offset: uint8): uint16 =
  assert offset mod 2 == 0

  let address: uint32 = addrOf(bus, dev, fn, offset)

  portOut32(0xcf8, address)
  var dword = portIn32(0xcfc) shr ((offset and 0x2) * 8)

  result = dword.uint16

proc dumpPciDeviceFunction(bus, dev, fn: uint8) =

  let vendorId = pciConfigRead16(bus, dev, fn, 0)
  let deviceId = pciConfigRead16(bus, dev, fn, 2)
  let class = pciConfigRead16(bus, dev, fn, 0xa)

  println("")
  println(&"  Function={fn}")
  println(&"  Vendor ID      = {vendorId:0>4x}h")
  println(&"  Device ID      = {deviceId:0>4x}h")
  println(&"  Class          = {class shr 8:0>2x}h")
  println(&"  SubClass       = {class and 0xf:0>2x}h")

proc dumpPciDevice(bus, dev: uint8) =
  let vendorId = pciConfigRead16(bus, dev, 0, 0)
  if vendorId == 0xffff:
    return

  let headerType = pciConfigRead16(bus, dev, 0, 0xe)
  let isMultiFunction = (headerType and 0x80) shr 7

  println("")
  println(&"Bus={bus}, Device={dev}")

  dumpPciDeviceFunction(bus, dev, 0)
  if isMultiFunction == 1:
    for f in 1.uint8..7:
      let vendorId = pciConfigRead16(bus, dev, f, 0)
      if vendorId == 0xffff:
        continue
      dumpPciDeviceFunction(bus, dev, f)

proc dumpPciConfig*() =
  println("")
  println("PCI Configuration")

  dumpPciDevice(0, 0)

  for dev in 1.uint8 ..< 32:
    dumpPciDevice(0, dev)
