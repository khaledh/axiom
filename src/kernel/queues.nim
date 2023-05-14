import condition
import debug
import lock

type
  BlockingQueue*[T] = ref object of RootObj
    maxSize*: int
    queue*: seq[T]
    lock*: Lock
    notEmpty*: ConditionVar
    notFull*: ConditionVar

proc newBlockingQueue*[T](maxSize: int): BlockingQueue[T] =
  result = BlockingQueue[T]()
  result.maxSize = maxSize
  result.queue = @[]
  result.lock = newSpinLock()
  result.notEmpty = newConditionVar()
  result.notFull = newConditionVar()

proc enqueue*[T](q: BlockingQueue[T], item: T) =
  debugln("blockingQ.enqueue: acquiring lock")
  q.lock.acquire
  debugln("blockingQ.enqueue: acquired lock")
  while q.queue.len == q.maxSize:
    debugln("blockingQ.enqueue: waiting for notFull")
    q.notFull.wait(q.lock)
  debugln("blockingQ.enqueue: notFull signaled, adding item")
  q.queue.add(item)
  debugln("blockingQ.enqueue: signaling notEmpty")
  q.notEmpty.signal
  debugln("blockingQ.enqueue: releasing lock")
  q.lock.release

proc enqueueNoWait*[T](q: BlockingQueue[T], item: T) =
  q.lock.acquire
  if q.queue.len < q.maxSize:
    q.queue.add(item)
    q.notEmpty.signal
  q.lock.release

proc dequeue*[T](q: BlockingQueue[T]): T =
  debugln("blockingQ.dequeue: acquiring lock")
  q.lock.acquire
  debugln("blockingQ.dequeue: acquired lock")
  while q.queue.len == 0:
    debugln("blockingQ.dequeue: waiting for notEmpty")
    q.notEmpty.wait(q.lock)
  debugln("blockingQ.dequeue: notEmpty signaled, popping item")
  result = q.queue.pop
  debugln("blockingQ.dequeue: signaling notFull")
  q.notFull.signal
  debugln("blockingQ.dequeue: releasing lock")
  q.lock.release

proc dequeueNoWait*[T](q: BlockingQueue[T]): T =
  debugln("blockingQ.dequeueNoWait: acquiring lock")
  q.lock.acquire
  debugln("blockingQ.dequeueNoWait: acquired lock")
  if q.queue.len > 0:
    debugln("blockingQ.dequeueNoWait: popping item")
    result = q.queue.pop
    debugln("blockingQ.dequeueNoWait: signaling notFull")
    q.notFull.signal
  debugln("blockingQ.dequeueNoWait: releasing lock")
  q.lock.release
