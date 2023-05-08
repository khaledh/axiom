import std/strformat
import std/tables

import ../devices/console
import ../devices/pci {.all.}


proc showPciDeviceFunction(bus, dev, fn: uint8) =

  let
    pciId = pciConfigRead32(bus, dev, fn, 0)
    vendorId = pciId and 0xffff
    deviceId = pciId shr 16

    class = pciConfigRead32(bus, dev, fn, 8)
    baseClass = class shr 24
    subClass = (class shr 16) and 0xff
    progIF = (class shr 8) and 0xff

    interrupt = pciConfigRead16(bus, dev, fn, 0x3c)
    intLine = interrupt and 0xff
    intPin = interrupt shr 8

    # status = pciConfigRead16(bus, dev, fn, 6)

  let desc = PciClassCode.getOrDefault((baseClass.uint8, subClass.uint8, progIF.uint8), "")

  write(&"  pci {bus:0>2x}:{dev:0>2x}.{fn} -> {vendorId:0>4x}:{deviceId:0>4x} ({baseClass:0>2x}h,{subClass:0>2x}h,{progIF:0>2x}h)")
  write(&"  {desc}, interrupt: pin({intPin}) line({intLine})")

  var
    capOffset = pciConfigRead16(bus, dev, fn, 0x34).uint8
    capValue: uint8
    nextCapOffset: uint8

  if capOffset != 0:
    write(", capabilities:")
    while capOffset != 0:
      (capValue, nextCapOffset) = pciNextCapability(bus, dev, fn, capOffset)
      write(&" {capValue:0>2x}={cast[PciCapability](capValue)}")
      if capValue == 0x12: # Sata Data-Index Configuration
        let revision = pciConfigRead16(bus, dev, fn, capOffset + 2)
        write(&" revision={(revision shr 4) and 0xf}.{revision and 0xf}")
        let satacr1 = pciConfigRead16(bus, dev, fn, capOffset + 4)
        write(&" barloc={satacr1 and 0xf:0>4b}b, barofst={(satacr1 shr 4) and 0xfffff:0>5x}h")
      capOffset = nextCapOffset

  writeln("")

proc showPciDevice(bus, dev: uint8) =
  let vendorId = pciConfigRead16(bus, dev, 0, 0)
  if vendorId == 0xffff:
    return

  let headerType = pciConfigRead16(bus, dev, 0, 0xe)
  let isMultiFunction = (headerType and 0x80) shr 7

  writeln("")

  showPciDeviceFunction(bus, dev, 0)
  if isMultiFunction == 1:
    for f in 1.uint8..7:
      let vendorId = pciConfigRead16(bus, dev, f, 0)
      if vendorId == 0xffff:
        continue
      showPciDeviceFunction(bus, dev, f)

proc showPciConfig*() =
  writeln("")
  writeln("PCI Configuration")

  showPciDevice(0, 0)

  for dev in 1.uint8 ..< 32:
    showPciDevice(0, dev)
