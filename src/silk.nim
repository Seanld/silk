import std/asyncnet
import std/asyncdispatch
import std/tables
import std/logging

import ./silk/serverconfig
import ./silk/status
import ./silk/headers
import ./silk/context
import ./silk/router
import ./silk/middleware/base

export status
export headers
export context
export router
export serverconfig

type Server* = ref object
  config*: ServerConfig

  # Manages routing of paths to handlers.
  router*: Router

  # All the log handlers to be used by the server.
  loggers*: seq[Logger]

  # Active middleware.
  middleware: seq[Middleware]

proc newServer*(config: ServerConfig): Server =
  return Server(
    config: config,
    loggers: @[],
    router: newRouter(),
  )

proc dispatchClient(s: Server, client: AsyncSocket) {.async.} =
  ## Executed as soon as a new connection is made.
  var req: Request
  try:
    req = await client.recvReq(s.config.maxContentLen)
  except EmptyRequestDefect:
    # If request is empty (no data was sent), close connection early.
    client.close()
    return

  # Send request through middleware pipeline.
  for mw in s.middleware:
    req = mw.processRequest(req)

  # Dispatch context to router to obtain a relevant `Response`.
  var ctx = newContext(client, req)
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
    let client = await server.accept()
    try:
      asyncCheck s.dispatchClient(client)
    except Exception as e:
      error(e.msg)

proc start*(s: Server) =
  ## Start HTTP server and run infinitely.
  # Register loggers.
  for l in s.loggers:
    addHandler(l)

  # Init all middleware.
  for m in s.middleware:
    m.init()

  asyncCheck s.serve()
  runForever()
