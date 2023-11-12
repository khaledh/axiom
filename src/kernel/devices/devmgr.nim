#[
  Device Manager
]#

import std/tables

import bga
import pci

type
  PciDeviceInitializer = proc (dev: PciDeviceConfig) {.nimcall.}

let
  # map of (vendorId, deviceId) to device initializer
  PciDeviceInitializers: Table[(uint16, uint16), PciDeviceInitializer] = {
    (0x1234'u16, 0x1111'u16): bga.initPci,
  }.toTable


proc init*() =
  for dev in enumeratePciBus(0):
    let devInit = PciDeviceInitializers.getOrDefault((dev.vendorId, dev.deviceId), nil)
    if not devInit.isNil:
      devInit(dev)
