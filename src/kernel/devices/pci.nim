import std/strformat
import std/tables

import console
import ports


const
  PciClassCode = {
    (0x00'u8, 0x00'u8, 0x00'u8): "Existing device except VGA-compatible",
    (0x00'u8, 0x01'u8, 0x00'u8): "VGA-compatible device",

    (0x01'u8, 0x00'u8, 0x00'u8): "SCSI controller",
    (0x01'u8, 0x00'u8, 0x11'u8): "SCSI storage device (SOP/PQI)",
    (0x01'u8, 0x00'u8, 0x12'u8): "SCSI controller (SOP/PQI)",
    (0x01'u8, 0x00'u8, 0x13'u8): "SCSI storage device and SCSI controller (SOP/PQI)",
    (0x01'u8, 0x00'u8, 0x21'u8): "SCSI storage device (SOP/NVMe)",
    (0x01'u8, 0x01'u8, 0x00'u8): "IDE controller",
    (0x01'u8, 0x02'u8, 0x00'u8): "Floppy disk controller",
    (0x01'u8, 0x03'u8, 0x00'u8): "IPI bus controller",
    (0x01'u8, 0x04'u8, 0x00'u8): "RAID controller",
    (0x01'u8, 0x05'u8, 0x20'u8): "ATA controller with ADMA interface - single stepping",
    (0x01'u8, 0x05'u8, 0x30'u8): "ATA controller with ADMA interface - continuous operation",
    (0x01'u8, 0x06'u8, 0x00'u8): "Serial ATA controller",
    (0x01'u8, 0x06'u8, 0x01'u8): "Serial ATA controller - AHCI",
    (0x01'u8, 0x06'u8, 0x02'u8): "Serial Storage Bus Interface",
    (0x01'u8, 0x07'u8, 0x00'u8): "Serial Attached SCSI (SAS) controller",
    (0x01'u8, 0x08'u8, 0x00'u8): "NVM subsystem",
    (0x01'u8, 0x08'u8, 0x01'u8): "NVM subsystem NVMHCI",
    (0x01'u8, 0x08'u8, 0x02'u8): "NVM Express (NVMe) I/O controller",
    (0x01'u8, 0x08'u8, 0x03'u8): "NVM Express (NVMe) administrative controller",
    (0x01'u8, 0x09'u8, 0x00'u8): "Universal Flash Storage (UFS) controller",
    (0x01'u8, 0x09'u8, 0x01'u8): "Universal Flash Storage (UFS) controller - UFSHCI",
    (0x01'u8, 0x80'u8, 0x00'u8): "Other mass storage controller",

    (0x02'u8, 0x00'u8, 0x00'u8): "Ethernet controller",
    (0x02'u8, 0x01'u8, 0x00'u8): "Token Ring controller",
    (0x02'u8, 0x02'u8, 0x00'u8): "FDDI controller",
    (0x02'u8, 0x03'u8, 0x00'u8): "ATM controller",
    (0x02'u8, 0x04'u8, 0x00'u8): "ISDN controller",
    (0x02'u8, 0x05'u8, 0x00'u8): "WorldFip controller",
    (0x02'u8, 0x06'u8, 0x00'u8): "PICMG 2.14 Mutli Computing",
    (0x02'u8, 0x07'u8, 0x00'u8): "InfiniBand controller",
    (0x02'u8, 0x08'u8, 0x00'u8): "Host fabric controller",
    (0x02'u8, 0x80'u8, 0x00'u8): "Other network controller",

    (0x03'u8, 0x00'u8, 0x00'u8): "VGA-compatible controller",
    (0x03'u8, 0x00'u8, 0x01'u8): "8514-compatible controller",
    (0x03'u8, 0x10'u8, 0x00'u8): "XGA controller",
    (0x03'u8, 0x20'u8, 0x00'u8): "3D controller",
    (0x03'u8, 0x80'u8, 0x00'u8): "Other display controller",

    (0x04'u8, 0x00'u8, 0x00'u8): "Video device",
    (0x04'u8, 0x01'u8, 0x00'u8): "Audio device",
    (0x04'u8, 0x02'u8, 0x00'u8): "Computer telephony device",
    (0x04'u8, 0x03'u8, 0x00'u8): "High Definition Audio (HD-A) 1.0 compatible",
    (0x04'u8, 0x03'u8, 0x80'u8): "High Definition Audio (HD-A) 1.0 compatible with extensions",
    (0x04'u8, 0x80'u8, 0x00'u8): "Other multimedia device",

    (0x05'u8, 0x00'u8, 0x00'u8): "RAM",
    (0x05'u8, 0x10'u8, 0x00'u8): "Flash",
    (0x05'u8, 0x80'u8, 0x00'u8): "Other memory controller",

    (0x06'u8, 0x00'u8, 0x00'u8): "Host bridge",
    (0x06'u8, 0x01'u8, 0x00'u8): "ISA bridge",
    (0x06'u8, 0x02'u8, 0x00'u8): "EISA bridge",
    (0x06'u8, 0x03'u8, 0x00'u8): "MCA bridge",
    (0x06'u8, 0x04'u8, 0x00'u8): "PCI-to-PCI bridge",
    (0x06'u8, 0x04'u8, 0x01'u8): "Subtractive Decode PCI-to-PCI bridge",
    (0x06'u8, 0x05'u8, 0x00'u8): "PCMCIA bridge",
    (0x06'u8, 0x06'u8, 0x00'u8): "NuBus bridge",
    (0x06'u8, 0x07'u8, 0x00'u8): "CardBus bridge",
    (0x06'u8, 0x08'u8, 0x00'u8): "RACEway bridge",
    (0x06'u8, 0x09'u8, 0x40'u8): "Semi-transparent PCI-to-PCI bridge with host-facing primary",
    (0x06'u8, 0x09'u8, 0x80'u8): "Semi-transparent PCI-to-PCI bridge with host-facing secondary",
    (0x06'u8, 0x0a'u8, 0x00'u8): "InfiniBand-to-PCI host bridge",
    (0x06'u8, 0x0b'u8, 0x00'u8): "Advanced Switching-to-PCI host bridge - Custom Interface",
    (0x06'u8, 0x0b'u8, 0x01'u8): "Advanced Switching-to-PCI host bridge - ASI-SIG Interface",
    (0x06'u8, 0x80'u8, 0x00'u8): "Other bridge device",

    (0x0c'u8, 0x00'u8, 0x00'u8): "IEEE 1394 (FireWire)",
    (0x0c'u8, 0x00'u8, 0x01'u8): "IEEE 1394 - OpenHCI",
    (0x0c'u8, 0x01'u8, 0x00'u8): "ACCESS.bus",
    (0x0c'u8, 0x02'u8, 0x00'u8): "SSA",
    (0x0c'u8, 0x03'u8, 0x00'u8): "USB - UHCI",
    (0x0c'u8, 0x03'u8, 0x10'u8): "USB - OHCI",
    (0x0c'u8, 0x03'u8, 0x20'u8): "USB2 - EHCI",
    (0x0c'u8, 0x03'u8, 0x30'u8): "USB - xHCI",
    (0x0c'u8, 0x03'u8, 0x40'u8): "USB4 Host Interface",
    (0x0c'u8, 0x03'u8, 0x80'u8): "USB host controller",
    (0x0c'u8, 0x03'u8, 0xfe'u8): "USB device",
    (0x0c'u8, 0x04'u8, 0x00'u8): "Fibre Channel",
    (0x0c'u8, 0x05'u8, 0x00'u8): "SMBus",
    (0x0c'u8, 0x06'u8, 0x00'u8): "InfiniBand (deprecated)",
    (0x0c'u8, 0x07'u8, 0x00'u8): "IPMI SMIC Interface",
    (0x0c'u8, 0x07'u8, 0x01'u8): "IPMI Keyboard Controller Style Interface",
    (0x0c'u8, 0x07'u8, 0x02'u8): "IPMI Block Transfer Interface",
    (0x0c'u8, 0x08'u8, 0x00'u8): "SERCOS Interface Standard",
    (0x0c'u8, 0x09'u8, 0x00'u8): "CANbus",
    (0x0c'u8, 0x0a'u8, 0x00'u8): "MIPI I3C Host Controller Interface",
    (0x0c'u8, 0x80'u8, 0x00'u8): "Other Serial Bus controllers",
  }.toTable

type
  PciCapability = enum
    Null
    PowerManagement
    Agp
    VitalProductData
    SlotIdentification
    Msi
    CompactPciHotSwap
    PciX
    HyperTransport
    VendorSpecific
    DebugPort
    CompactPCICentralResourceControl
    PciHotPlug
    PciBrdigeSubsystemVendorId
    Agp8x
    SecureDevice
    PciExpress
    MsiX
    SataDataIndexConfiguration
    AdvancedFeatures
    EnhancedAllocation
    FlatteningPortalBridge

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

proc pciNextCapability*(bus, dev, fn, offset: uint8): tuple[capValue: uint8, nextOffset: uint8] =
  let
    capReg = pciConfigRead16(bus, dev, fn, offset)
    capValue = (capReg and 0xff).uint8
    nextOffset = (capReg shr 8).uint8

  result = (capValue, nextOffset)


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
