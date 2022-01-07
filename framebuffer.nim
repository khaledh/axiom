type
  Framebuffer* = object
    buffer: ptr UncheckedArray[uint32]
    width: uint32
    height: uint32
    pitch: uint32

proc initFramebuffer*(address: uint64, width, height: uint32, pitch: uint32 = 0): Framebuffer =
    Framebuffer(
        buffer: cast[ptr UncheckedArray[uint32]](address),
        width: width,
        height: height,
        pitch: if pitch == 0: width else: pitch
    )

proc `[]=`*(fb: Framebuffer, x, y: int, color: uint32) =
    if x < fb.width.int and y < fb.height.int:
        fb.buffer[y*fb.pitch.int + x] = color

# proc pixel*(fb: Framebuffer, x, y: uint32, color: uint32) =
#     fb.buffer[y*fb.pitch + x] = color

proc clear*(fb: Framebuffer, color: uint32 = 0) =
  for i in 0 ..< (fb.width * fb.pitch):
    fb.buffer[i] = color
