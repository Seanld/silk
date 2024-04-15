import std/asyncnet
import std/asyncdispatch
import std/tables

import ./status
import ./headers
import ./context
import ./router

export status
export headers
export context
export router

type Server* = ref object
  host*: string
  port*: Port

  # How many clients to handle at one time, before new connections are dropped.
  maxClients* = 100

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
  var
    reqHeader = (await client.recvReqHeader()).parseReqHeader()
    ctx = newContext(client)

  await s.router.handleRoute(reqHeader.path, ctx)

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
