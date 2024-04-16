import std/asyncnet
import std/asyncdispatch
import std/tables
from std/math import `^`

import ./status
import ./headers
import ./context
import ./router
import ./middleware

export status
export headers
export context
export router

type Server* = ref object
  host*: string
  port*: Port

  # How many clients to handle at one time, before new connections are dropped.
  maxClients* = 100
  # Limit content body size to a max size of 256 megabytes by default.
  maxContentLen* = 2^28

  # Manages routing of paths to handlers.
  router*: Router

proc newServer*(host: string, port: Port, maxClients: int = 100): Server =
  return Server(
    host: host,
    port: port,
    maxClients: maxClients,
    router: newRouter(),
  )

proc dispatchClient(s: Server, client: AsyncSocket) {.async.} =
  ## Executed as soon as a new connection is made.
  # let headerStr = await recvReqHeaderStr()
  var req = await client.recvReq(s.maxContentLen)
  await s.router.dispatchRoute(req, newContext(client, req))
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
