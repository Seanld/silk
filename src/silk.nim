import std/asyncnet
import std/asyncdispatch
import std/logging
import std/tables
import std/typedthreads
from nativesockets import Port

import ./silk/serverconfig
import ./silk/status
import ./silk/headers
import ./silk/context
import ./silk/router
import ./silk/middleware
import ./silk/sugar

export tables.`[]`, tables.`[]=`
export nativesockets.Port

export asyncdispatch
export status
export headers
export context
export router
export serverconfig
export middleware
export sugar

type
  Server* = ref object
    config*: ServerConfig

    # Manages routing of paths to handlers.
    router*: Router

    loggers: seq[Logger]

    # Active middleware.
    middleware*: seq[Middleware]

    workers: seq[ref Thread[Server]]
    workQueue: ref Channel[AsyncSocket]

proc newServer*(config: ServerConfig, loggers = @[newConsoleLogger().Logger], middleware: seq[Middleware] = @[]): Server =
  for l in loggers:
    addHandler(l)

  Server(
    config: config,
    router: newRouter(),
    loggers: loggers,
    middleware: middleware,
    workQueue: new Channel[AsyncSocket],
  )

proc addLogger*(s: Server, l: Logger) =
  s.loggers.add(l)
  addHandler(l)

proc GET*(s: Server, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  s.router.GET(path, handler, middleware)
proc POST*(s: Server, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  s.router.POST(path, handler, middleware)
proc PUT*(s: Server, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  s.router.PUT(path, handler, middleware)
proc DELETE*(s: Server, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  s.router.DELETE(path, handler, middleware)

proc dispatchClient(s: Server, client: AsyncSocket) {.async, gcsafe.} =
  ## Executed as soon as a new connection is made.
  var req: Request
  try:
    req = await client.recvReq(s.config.maxContentLen)
  except EmptyRequestDefect:
    # If request is empty (no data was sent), close connection early.
    client.close()
    return

  var ctx = newContext(client, req)

  var skip = false

  # Send request through middleware pipeline.
  for mw in s.middleware:
    let status = await mw.processRequest(ctx, req)
    if status == SKIP_ROUTING:
      skip = true
      break

  # Dispatch context to router to obtain a relevant `Response`.
  if not skip:
    await s.router.dispatchRoute(s.config, req.path, ctx)

  # Send response through middleware pipeline.
  for mw in s.middleware:
    discard await mw.processResponse(ctx, ctx.resp)

  # Send response to client.
  await client.send($ctx.resp)
  client.close()

proc dispatchClientPrecheck(s: Server, client: AsyncSocket) {.async, gcsafe.} =
  ## Handles exceptions from entire request/route/response
  ## dispatching process. Necessary for keep-alive.

  try:
    await s.dispatchClient(client)
  except:
    echo getCurrentExceptionMsg()
    if not s.config.keepAlive:
      raise
    client.close()
    error(getCurrentExceptionMsg())

proc workerLoop(s: Server) {.thread.} =
  ## The main loop each worker runs. New incoming connections are communicated
  ## over the worker's channel from the main thread. When one is received, it
  ## is dispatched asynchronously, to allow for multiple connections to be
  ## multiplexed on the same worker's thread, effectively combining parallelism
  ## *and* concurrency, for maximum throughput.

  while true:
    let msg = s.workQueue[].recv()
    echo repr(msg)
    asyncCheck s.dispatchClientPrecheck(msg)

  runForever()

proc serve(s: Server) {.async.} =
  ## Runs in main thread. Receives connections and delegates them to workers
  ## to be processed, and to be responded to.

  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(s.config.port, s.config.host)
  server.listen()

  while true:
    let client = await server.accept()
    try:
      s.workQueue[].send(client)
    except:
      discard

proc start*(s: Server) =
  ## Start HTTP server and run infinitely.

  s.workQueue[].open()

  # Init all middleware.
  for m in s.middleware:
    m.init()

  for wn in 0 ..< s.config.threads:
    var newThread = new Thread[Server]
    createThread(newThread[], workerLoop, s)
    s.workers.add(newThread)

  asyncCheck s.serve()
  runForever()
