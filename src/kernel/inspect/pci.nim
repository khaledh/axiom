import std/strformat

import ../devices/console
import ../devices/pci {.all.}


proc showPciDevice(dev: PciDeviceConfig) =
  write(&"  pci {dev.bus:0>2x}:{dev.slot:0>2x}.{dev.fn} -> {dev.vendorId:0>4x}:{dev.deviceId:0>4x}")
  write(&" {dev.classCode:0>2x}h,{dev.subClass:0>2x}h,{dev.progIF:0>2x}h)")
  write(&"  {dev.desc}, interrupt: pin({dev.interruptPin}) line({dev.interruptLine})")

  for cap in dev.capabilities:
      write(&" {cap}")
      # if cap.uint8 == 0x12: # Sata Data-Index Configuration
      #   let revision = pciConfigRead16(bus, dev, fn, capOffset + 2)
      #   write(&" revision={(revision shr 4) and 0xf}.{revision and 0xf}")
      #   let satacr1 = pciConfigRead16(bus, dev, fn, capOffset + 4)
      #   write(&" barloc={satacr1 and 0xf:0>4b}b, barofst={(satacr1 shr 4) and 0xfffff:0>5x}h")

  writeln("")
  writeln(&"    BAR0: {dev.bar[0]:0>8x}h")
  writeln(&"    BAR1: {dev.bar[1]:0>8x}h")
  writeln(&"    BAR2: {dev.bar[2]:0>8x}h")
  writeln(&"    BAR3: {dev.bar[3]:0>8x}h")
  writeln(&"    BAR4: {dev.bar[4]:0>8x}h")
  writeln(&"    BAR5: {dev.bar[5]:0>8x}h")

  writeln("")


proc showPciConfig*() =
  writeln("")
  writeln("PCI Configuration")

  for dev in enumeratePciBus(0):
    showPciDevice(dev)
