import std/asyncnet
import std/asyncdispatch
import std/logging
import std/tables
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

type Server* = ref object
  config*: ServerConfig

  # Manages routing of paths to handlers.
  router*: Router

  loggers: seq[Logger]

  # Active middleware.
  middleware*: seq[Middleware]

proc newServer*(config: ServerConfig, loggers = @[newConsoleLogger().Logger], middleware: seq[Middleware] = @[]): Server =
  result = Server(
    config: config,
    router: newRouter(),
    loggers: loggers,
    middleware: middleware,
  )
  for l in loggers:
    addHandler(l)

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

proc dispatchClient(s: Server, client: AsyncSocket) {.async.} =
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

proc dispatchClientPrecheck(s: Server, client: AsyncSocket) {.async.} =
  ## Handles exceptions from entire request/route/response
  ## dispatching process. Necessary for keep-alive.
  try:
    await s.dispatchClient(client)
  except:
    if not s.config.keepAlive:
      raise
    client.close()
    error(getCurrentExceptionMsg())

proc serve(s: Server) {.async.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(s.config.port, s.config.host)
  server.listen()

  while true:
    let client = await server.accept()
    asyncCheck s.dispatchClientPrecheck(client)

proc start*(s: Server) =
  ## Start HTTP server and run infinitely.

  # Init all middleware.
  for m in s.middleware:
    m.init()

  asyncCheck s.serve()
  runForever()
