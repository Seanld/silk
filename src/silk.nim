import std/logging
import std/tables
import std/net
from nativesockets import Port

import ./silk/serverconfig
import ./silk/status
import ./silk/headers
import ./silk/context
import ./silk/router
import ./silk/middleware
import ./silk/sugar
import ./silk/serverlogger

export tables.`[]`, tables.`[]=`
export nativesockets.Port

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

    # Active middleware.
    middleware*: seq[Middleware]

proc newServer*(config: ServerConfig, middleware: seq[Middleware] = @[]): Server =
  result = Server(
    config: config,
    router: newRouter(),
    middleware: middleware,
  )

proc GET*(s: Server, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  s.router.GET(path, handler, middleware)
proc POST*(s: Server, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  s.router.POST(path, handler, middleware)
proc PUT*(s: Server, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  s.router.PUT(path, handler, middleware)
proc DELETE*(s: Server, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  s.router.DELETE(path, handler, middleware)

proc dispatchClient(s: Server, client: Socket) {.gcsafe.} =
  ## Executed as soon as a new connection is made.
  var req: Request
  try:
    req = client.recvReq(s.config.maxContentLen)
  except EmptyRequestDefect:
    # If request is empty (no data was sent), close connection early.
    client.close()
    return

  var ctx = newContext(client, req)

  var skip = false

  # Send request through middleware pipeline.
  for mw in s.middleware:
    let status = mw.processRequest(ctx, req)
    if status == SKIP_ROUTING:
      skip = true
      break

  # Dispatch context to router to obtain a relevant `Response`.
  if not skip:
    s.router.dispatchRoute(s.config, req.path, ctx)

  # Send response through middleware pipeline.
  for mw in s.middleware:
    discard mw.processResponse(ctx, ctx.resp)

  # Send response to client.
  client.send($ctx.resp)
  client.close()

proc dispatchClientPrecheck(s: Server, client: Socket) {.gcsafe.} =
  ## Handles exceptions from entire request/route/response
  ## dispatching process. Necessary for keep-alive.

  try:
    s.dispatchClient(client)
  except:
    if not s.config.keepAlive:
      raise
    client.close()
    error(getCurrentExceptionMsg())

proc workerLoop(s: Server) {.thread.} =
  # Register log handlers per-thread.
  var sock = newSocket()
  sock.setSockOpt(OptReuseAddr, true)
  sock.setSockOpt(OptReusePort, true)
  sock.setSockOpt(OptNoDelay, true, level=IPPROTO_TCP.cint)
  sock.bindAddr(s.config.port, s.config.host)
  sock.listen()

  var client: Socket
  while true:
    sock.accept(client)
    s.dispatchClientPrecheck(client)

proc start*(s: Server) =
  ## Start HTTP server and run infinitely.

  # Init all middleware.
  for m in s.middleware:
    m.init()

  # Create logger thread if logging is enabled. Worker threads
  # push log messages to a queue, which this thread churns through.
  if s.config.serverLogger != nil and s.config.serverLogger.loggers.len > 0:
    var logWorkerThread: Thread[ServerLogger]
    createThread[ServerLogger](logWorkerThread, logLoop, s.config.serverLogger)

  var workers = newSeq[Thread[Server]](s.config.workers)

  for w in 0 ..< s.config.workers:
    createThread[Server](workers[w], workerLoop, s)

  joinThreads(workers)
