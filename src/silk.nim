import std/asyncnet
import std/asyncdispatch
import std/tables
import std/logging
from std/math import `^`

import ./silk/status
import ./silk/headers
import ./silk/context
import ./silk/router
import ./silk/middleware

export status
export headers
export context
export router

type Server* = ref object
  host*: string
  port*: Port

  # How many clients to handle at one time, before new connections are dropped.
  maxClients*: int
  # Limit content body size to a max size of 256 megabytes by default.
  maxContentLen*: int

  # Manages routing of paths to handlers.
  router*: Router

  # Active middleware.
  middleware: seq[Middleware]

proc newServer*(host: string, port: Port, maxClients: int = 100, maxContentLen: int = 2^28): Server =
  return Server(
    host: host,
    port: port,
    maxClients: maxClients,
    maxContentLen: maxContentLen,
    router: newRouter(),
  )

proc dispatchClient(s: Server, client: AsyncSocket) {.async.} =
  ## Executed as soon as a new connection is made.
  var req: Request
  try:
    req = await client.recvReq(s.maxContentLen)
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
  server.bindAddr(s.port, s.host)
  server.listen()

  while true:
    let client = await server.accept()
    asyncCheck s.dispatchClient(client)

proc start*(s: Server) =
  asyncCheck s.serve()
  runForever()
