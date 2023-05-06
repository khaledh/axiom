import std/heapqueue

const
  StackSize = 512

type
  ThreadStackArray* = array[StackSize, uint64]
  ThreadStack* = ref ThreadStackArray

  ThreadState* = enum
    tsNew
    tsReady
    tsRunning
    tsBlocked
    tsSleeping
    tsTerminated

  ThreadPriority* = -7..8

  Thread* = ref object
    rsp*: uint64
    id*: uint64
    name*: string
    prev*: Thread
    next*: Thread
    stack*: ThreadStack
    priority*: ThreadPriority
    state*: ThreadState
    sleepUntil*: uint64

  ThreadFunc* = proc () {.cdecl.}

  SwitchStack* {.packed.} = object
    r15*: uint64
    r14*: uint64
    r13*: uint64
    r12*: uint64
    r11*: uint64
    r10*: uint64
    r9*: uint64
    r8*: uint64
    rdi*: uint64
    rsi*: uint64
    rbp*: uint64
    rbx*: uint64
    rdx*: uint64
    rcx*: uint64
    rax*: uint64
    rip*: uint64

# we want heap[0] to contian the thread with highest priority
# so we invert the inequality here
proc `<`*(a, b: Thread): bool = a.priority > b.priority

var
  thCurr*: Thread
  # priority queues
  readyQueue*: HeapQueue[Thread]
  blockedQueue*: HeapQueue[Thread]
  sleepingQueue*: HeapQueue[Thread]


proc switchToThread*(oldThread, newThread: Thread) {.asmNoStackFrame.} =
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

    sti
    ret
  """

proc jumpToThread*(thread: Thread) {.cdecl.} =
  # writeln("\njumpToThread()")

  thCurr = thread
  thCurr.state = tsRunning

  # showThreads()
  # writeln(&"thCurr.id = {thCurr.id}, thCurr @ {cast[uint64](thCurr):x}")
  asm """
    mov rsp, %0
    jmp resumeThread
    :
    :"g"(`thread`->rsp)
  """
