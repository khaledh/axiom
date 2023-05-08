#[
  Bochs VGA/VBE Graphics Adapter
]#
import std/strformat

import ports
import ../debug

const
  BgaPortIndex               = 0x1ce
  BgaPortValue               = 0x1cf

  BgaPortIndexId*            = 0x0
  BgaPortIndexXres           = 0x1
  BgaPortIndexYres           = 0x2
  BgaPortIndexBpp            = 0x3
  BgaPortIndexEnable         = 0x4
  # BgaPortIndexBank           = 0x5
  BgaPortIndexVirtWidth*     = 0x6
  BgaPortIndexVirtHeight*    = 0x7
  # BgaPortIndexXOffset        = 0x8
  BgaPortIndexYOffset        = 0x9
  # BgaPortIndexVideoMemory64K = 0xa
  # BgaPortIndexDdc            = 0xb

  # BgaId0                     = 0xB0C0
  # BgaId1                     = 0xB0C1
  # BgaId2                     = 0xB0C2
  # BgaId3                     = 0xB0C3
  # BgaId4                     = 0xB0C4
  # BgaId5                     = 0xB0C5

  # BgaBpp4                    = 0x04
  # BgaBpp8                    = 0x08
  # BgaBpp15                   = 0x0F
  # BgaBpp16                   = 0x10
  # BgaBpp24                   = 0x18
  # BgaBpp32                   = 0x20

  BgaDisabled                = 0x00
  BgaEnabled                 = 0x01
  # BgaGetCaps                 = 0x02
  # Bga8BitDac                 = 0x20
  BgaLfbEnabled              = 0x40
  # BgaNoClearMem              = 0x80

  BgaLfbPhysicalAddress*     = 0xc0000000'u32


proc bgaWriteRegister(index, value: uint16) =
  portOut16(BgaPortIndex, index)
  portOut16(BgaPortValue, value)

proc bgaReadRegister*(index: uint16): uint16 =
  portOut16(BgaPortIndex, index)
  portIn16(BgaPortValue)

proc bgaSetVideoMode*(width, height, bpp: uint16) =
  bgaWriteRegister(BgaPortIndexEnable, BgaDisabled)
  bgaWriteRegister(BgaPortIndexXres, width)
  bgaWriteRegister(BgaPortIndexYres, height)
  bgaWriteRegister(BgaPortIndexBpp, bpp)
  bgaWriteRegister(BgaPortIndexEnable, BgaEnabled or BgaLfbEnabled)

proc bgaSwapBuffers*() =
  bgaWriteRegister(BgaPortIndexYOffset, 1024)

proc init*() =
  let bgaId = bgaReadRegister(BgaPortIndexId)
  println(&"BGA ID = {bgaId:0>4x}")

  bgaSetVideoMode(1280, 1024, 32)

  let virtWidth = bgaReadRegister(BgaPortIndexVirtWidth)
  let virtHeight = bgaReadRegister(BgaPortIndexVirtHeight)
  println(&"BGA VirtualRes = {virtWidth}x{virtHeight}")
