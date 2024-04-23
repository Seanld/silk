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

export tables.`[]`, tables.`[]=`
export nativesockets.Port

export asyncdispatch
export status
export headers
export context
export router
export serverconfig
export middleware

type Server* = ref object
  config*: ServerConfig

  # Manages routing of paths to handlers.
  router*: Router

  loggers: seq[Logger]

  # Active middleware.
  middleware: seq[Middleware]

template `~>`*(expr: untyped): untyped =
  proc(ctx{.inject.}: Context) {.async.} = expr

proc newServer*(config: ServerConfig): Server =
  let defaultConsoleLogger = newConsoleLogger()
  result = Server(
    config: config,
    router: newRouter(),
    loggers: @[defaultConsoleLogger.Logger]
  )
  addHandler(defaultConsoleLogger)

proc addMiddleware*(s: Server, m: Middleware) =
  s.middleware.add(m)

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

# Any files underneath `rootPath` will be served when requested via GET.
proc staticDir*(s: Server, rootPath: string, localDir: string) =
  s.router.staticDir(rootPath, localDir)

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

  # Send request through middleware pipeline.
  for mw in s.middleware:
    ctx.req = mw.processRequest(req)

  # Dispatch context to router to obtain a relevant `Response`.
  await s.router.dispatchRoute(req, ctx)

  # Send response through middleware pipeline.
  for mw in s.middleware:
    ctx.resp = mw.processResponse(ctx.resp)

  # Send response to client.
  await client.send($ctx.resp)
  client.close()

proc serve(s: Server) {.async.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(s.config.port, s.config.host)
  server.listen()

  while true:
    try:
      let client = await server.accept()
      asyncCheck s.dispatchClient(client)
    except:
      if not s.config.keepAlive:
        raise
      error(getCurrentExceptionMsg())

proc start*(s: Server) =
  ## Start HTTP server and run infinitely.

  # Init all middleware.
  for m in s.middleware:
    m.init()

  asyncCheck s.serve()
  runForever()
