import std/strformat

import ../uefitypes
import ../../kernel/debug


proc showGop*(gop: ptr EfiGraphicsOutputProtocol) =
  println("")
  println("Graphics Output Protocol")
  println(&"  Current Mode    = {gop.mode.currentMode} (Max Mode={gop.mode.maxMode})")
  println(&"  Resolution      = {gop.mode.info.horizontalResolution} x {gop.mode.info.verticalResolution}")
  println(&"  Pixel Format    = {gop.mode.info.pixelFormat}")
  # println(&"  Pixel Info      = {gop.mode.info.pixelInfo}")
  println(&"  Pixels/ScanLine = {gop.mode.info.pixelsPerScanLine}")

  println("")
  var modeInfo: ptr GopModeInfo
  var sizeOfInfo: uint
  for i in 0..<gop.mode.maxMode:
    discard gop.queryMode(gop, i, addr sizeOfInfo, addr modeInfo)
    println(&"  Mode {i:>2}: {modeInfo.horizontalResolution:>4} x {modeInfo.verticalResolution:>4}")
