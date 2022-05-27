import std/strformat

import cpu
import debug

const
  StackSize = 512

type
  ThreadStack = ref array[StackSize, uint64]

  ThreadState = enum
    tsNew
    tsReady
    tsRunning
    tsTerminated

  ThreadPriority* = -7..8

  Thread* = ref object
    rsp: uint64
    id*: uint64
    prev: Thread
    next: Thread
    stack: ThreadStack
    priority: ThreadPriority
    state: ThreadState

  ThreadFunc* = proc () {.cdecl.}

  SwitchStack* {.packed.} = object
    r15: uint64
    r14: uint64
    r13: uint64
    r12: uint64
    r11: uint64
    r10: uint64
    r9: uint64
    r8: uint64
    rdi: uint64
    rsi: uint64
    rbp: uint64
    rbx: uint64
    rdx: uint64
    rcx: uint64
    rax: uint64
    rip: uint64

var
  thHead: Thread
  thTail: Thread
  thCurr: Thread
  # threads: array[4, Thread]
  # currThread: Thread
  nextAvailableId: uint64

proc contextSwitch*(oldThread, newThread: Thread) {.asmNoStackFrame.} =
  asm """
    push    rax
    push    rcx
    push    rdx
    push    rbx
    push    rbp
    push    rsi
    push    rdi
    push    r8
    push    r9
    push    r10
    push    r11
    push    r12
    push    r13
    push    r14
    push    r15

    # switch stacks
    mov     [rcx], rsp
    mov     rsp, [rdx]

    jmp resumeThread
  """

proc resumeThread*() {.asmNoStackFrame, exportc.} =
  asm """
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    pop     rdi
    pop     rsi
    pop     rbp
    pop     rbx
    pop     rdx
    pop     rcx
    pop     rax

    ret
  """

proc dumpThreads*() =
  # for i in 0..<len(threads):
  var thTemp = thHead
  println(&"id={thTemp.id}, addr={cast[uint64](thTemp):x}h, state={thTemp.state}, state={cast[uint64](thTemp.state):x}h")
  thTemp = thTemp.next

  while thTemp != thHead:
    println(&"id={thTemp.id}, addr={cast[uint64](thTemp):x}h, state={thTemp.state}, state={cast[uint64](thTemp.state):x}h")
    thTemp = thTemp.next

proc jumpToThread*(thread: Thread) {.cdecl.} =
  # println("\njumpToThread()")

  thCurr = thread
  thCurr.state = tsRunning

  # dumpThreads()
  # println(&"thCurr.id = {thCurr.id}, thCurr @ {cast[uint64](thCurr):x}")
  asm """
    mov rsp, %0
    jmp resumeThread
    :
    :"g"(`thread->rsp`)
  """

proc schedule*() =
  println("(s)")
  # dumpThreads()


  # println(&"thCurr.id: {thCurr.id:x}h, thCurr @ {cast[uint64](thCurr):x}")

  var thNext: Thread = thCurr
  var maxPriority =
    if thCurr.state != tsTerminated:
      thCurr.priority
    else:
      ThreadPriority.low

  # var nextId = (thCurr.id + 1) mod len(threads).uint64
  # println(&"(thCurr.id) = {(thCurr.id)}")
  # println(&"(thCurr.id + 1) = {(thCurr.id + 1)}")
  # println(&"(thCurr.id + 1) mod len(threads).uint64 = {(thCurr.id + 1) mod len(threads).uint64}")
  # println(&"len(threads): {len(threads)}")

  var thTemp = thCurr.next
  while thTemp.id != thCurr.id:
    # println(&"thTemp.id: {thTemp.id}, thTemp.state: {thTemp.state}")
    if thTemp.state == tsReady and thTemp.priority >= maxPriority:
      # println(&"new max: {thTemp.id}, pri={thTemp.priority}")
      thNext = thTemp
      maxPriority = thTemp.priority
    thTemp = thTemp.next

  # println(&"=> thNext.id: {thNext.id}, thNext.state: {thNext.state}")

  # if thCurr.state == tsTerminated:
  #   halt()
  # if thNext == thCurr:
  #   # same thread, no context switch
  #   return

  if thCurr.state == tsTerminated:
    jumpToThread(thNext)

  thCurr.state = tsReady
  thNext.state = tsRunning

  thTemp = thCurr
  thCurr = thNext

  contextSwitch(thTemp, thNext)

# proc terminateThread(thread: Thread) =
#   thread.state = tsTerminated

#   if thHead == thread:
#     thHead = thread.next
#   if thTail == thread:
#     thTail = thread.prev

#   thread.prev.next = thread.next
#   thread.next.prev = thread.prev

proc kernelThread(function: ThreadFunc) =
  # println("starting thread")
  function()

  disableInterrupts()

  if thCurr.next == thCurr:
    println("Halt")
    halt()

  # let thTemp = thCurr
  # thCurr = thCurr.prev
  # terminateThread(thTemp)
  thCurr.state = tsTerminated
  print("(k)")
  # halt()
  # thCurr.state = tsTerminated
  # println(&"thCurr.id: {thCurr.id}, thCurr.state: {thCurr.state}")

  # println(&"thread {thCurr.id} terminated")
  schedule()

proc createThread*(function: ThreadFunc, priority: ThreadPriority = 0): Thread =
  # if nextAvailableId >= len(threads).uint64:
  #   return nil

  var thNew = new(Thread)
  thNew.id = nextAvailableId
  thNew.state = tsNew
  thNew.priority = priority
  thNew.prev = nil
  thNew.next = nil

  thNew.stack = new(ThreadStack)
  thNew.rsp = cast[uint64](thNew.stack) + sizeof(ThreadStack).uint64 - sizeof(SwitchStack).uint64 - 128

  var ss = cast[ptr SwitchStack](thNew.rsp)
  zeroMem(ss, sizeof(SwitchStack))
  ss.rcx = cast[uint64](function)
  ss.rip = cast[uint64](kernelThread)
  # println(&"kernelThread @ {cast[uint64](kernelThread):x}")

  # threads[thNew.id] = thNew
  inc(nextAvailableId)

  if thHead.isNil:
    thHead = thNew
    thNew.prev = thHead
    thNew.next = thHead
  else:
    thNew.prev = thTail
    thNew.next = thTail.next
    thTail.next = thNew

  thTail = thNew

  result = thNew


proc startThread*(thread: Thread) =
  # println("\nstartThread()")
  # println(&"setting thread[{thread.id}] to ready")
  thread.state = tsReady

  # dumpThreads()

proc initThreads*() =
  nextAvailableId = 0
  thHead = nil
  thTail = nil
  thCurr = nil
