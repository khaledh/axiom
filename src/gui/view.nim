import graphics as gfx
import ../kernel/debug

type
  View* = ref object
    parent*: View
    children*: seq[View]
    buffer: ptr UncheckedArray[uint32]
    left*: uint32
    top*: uint32
    width*: uint32
    height*: uint32
    bgColor*: uint32
    leftAbs: uint32
    topAbs: uint32
    pitch: uint32
  MainView* = ref object
    view*: View
    title*: string

const
  TitleHeight* = 24

var
  rootView*: View
  childView*: View


proc `[]=`*(v: View, x, y: uint32, color: uint32) {.inline.} =
  # debugln("[view] set pixel: leftAbs=", $v.leftAbs, ", x=", $x, ", topAbs=", $v.topAbs, ", y=", $y)
  gfx.putPixelRel(v.leftAbs, v.topAbs, x, y, color)


proc createView*(parent: View, left, top, width, height: uint32, bgColor: uint32|Color = Black): View =
  result = new(View)
  result.left = left
  result.top = top
  result.width = width
  result.height = height
  result.bgColor = bgColor.uint32
  if parent != nil:
    parent.children.add(result)
    result.parent = parent
    result.leftAbs = parent.leftAbs + left
    result.topAbs = parent.topAbs + top
  else:
    result.leftAbs = left
    result.topAbs = top

proc createView*(x, y, width, height: uint32, bgColor: uint32|Color = Black): View =
  result = createView(rootView, x, y, width, height, bgColor)

proc createMainView*(title: string, x, y, width, height: uint32, bgColor: uint32|Color = Black): MainView =
  result = new(MainView)
  result.view = createView(rootView, x, y + TitleHeight, width, height - TitleHeight, bgColor)
  result.title = title
  # draw title
  gfx.fillrect(x, y, width, TitleHeight, Color.DarkGrey)
  gfx.putText(x + 4, y + 4, title, Color.DarkGrey, Color.White)

proc clear*(view: View) =
  gfx.fillrect(view.leftAbs, view.topAbs, view.width, view.height, view.bgColor)

proc scrollUp*(view: View, lines: uint32) =
  # debugln("[view] scrollUp: lines=", $lines)
  if lines >= view.height:
    view.clear()
  else:
    gfx.scrollUp(view.leftAbs, view.topAbs, view.width, view.height, lines, view.bgColor)

proc move(view: View, x, y: uint32) =
  view.left += x
  view.top += y
  view.leftAbs += x
  view.topAbs += y
  for child in view.children:
    move(child, x, y)


proc render(view: View) =
  # gfx.fillrect(view.leftAbs, view.topAbs, view.width, view.height, view.bgColor)
  for child in view.children:
    render(child)

proc render() =
  # rootView.render()
  discard

proc init*() =
  debugln("[view] Registering render callback")
  gfx.registerRenderCallback(render)
  
  debugln("[view] Creating root view")
  rootView = createView(nil, 0, 0, gfx.maxWidth(), gfx.maxHeight(), Color.Blue)
  rootView.clear()
