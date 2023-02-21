#[
  Bochs VGA/VBE Adapter
]#

import ../cpu

const
  BxvbePortIndex               = 0x1ce
  BxvbePortValue               = 0x1cf

  BxvbePortIndexId*            = 0x0
  BxvbePortIndexXres           = 0x1
  BxvbePortIndexYres           = 0x2
  BxvbePortIndexBpp            = 0x3
  BxvbePortIndexEnable         = 0x4
  # BxvbePortIndexBank           = 0x5
  BxvbePortIndexVirtWidth*     = 0x6
  BxvbePortIndexVirtHeight*    = 0x7
  # BxvbePortIndexXOffset        = 0x8
  BxvbePortIndexYOffset        = 0x9
  # BxvbePortIndexVideoMemory64K = 0xa
  # BxvbePortIndexDdc            = 0xb

  # BxvbeId0                     = 0xB0C0
  # BxvbeId1                     = 0xB0C1
  # BxvbeId2                     = 0xB0C2
  # BxvbeId3                     = 0xB0C3
  # BxvbeId4                     = 0xB0C4
  # BxvbeId5                     = 0xB0C5

  # BxvbeBpp4                    = 0x04
  # BxvbeBpp8                    = 0x08
  # BxvbeBpp15                   = 0x0F
  # BxvbeBpp16                   = 0x10
  # BxvbeBpp24                   = 0x18
  # BxvbeBpp32                   = 0x20

  BxvbeDisabled                = 0x00
  BxvbeEnabled                 = 0x01
  # BxvbeGetCaps                 = 0x02
  # Bxvbe8BitDac                 = 0x20
  BxvbeLfbEnabled              = 0x40
  # BxvbeNoClearMem              = 0x80

  BxvbeLfbPhysicalAddress*     = 0xc0000000'u32


proc bxvbeWriteRegister(index, value: uint16) =
  portOut16(BxvbePortIndex, index)
  portOut16(BxvbePortValue, value)

proc bgaReadRegister*(index: uint16): uint16 =
  portOut16(BxvbePortIndex, index)
  portIn16(BxvbePortValue)

proc bgaSetVideoMode*(width, height, bpp: uint16) =
  bxvbeWriteRegister(BxvbePortIndexEnable, BxvbeDisabled)
  bxvbeWriteRegister(BxvbePortIndexXres, width)
  bxvbeWriteRegister(BxvbePortIndexYres, height)
  bxvbeWriteRegister(BxvbePortIndexBpp, bpp)
  bxvbeWriteRegister(BxvbePortIndexEnable, BxvbeEnabled or BxvbeLfbEnabled)

proc bgaSwapBuffers*() =
  bxvbeWriteRegister(BxvbePortIndexYOffset, 1024)
