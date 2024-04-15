import std/asyncnet
import std/asyncdispatch

import ./status
import ./headers

type Server* = ref object
  host*: string
  port*: Port
  # How many clients to handle at one time, before new connections are dropped.
  maxClients* = 100

  clients: seq[AsyncSocket]

proc newServer*(host: string, port: Port, maxClients: int = 100): Server =
  return Server(
    host: host,
    port: port,
    maxClients: maxClients,

    clients: newSeq[AsyncSocket](),
  )

proc handleClient(s: Server, client: AsyncSocket) {.async.} =
  var
    reqHeader = (await client.recvReqHeader()).parseReqHeader()
    resp = ""

  if reqHeader.path == "/test":
    resp = fmtResponseHeader(STATUS_OK, ("Server", "Silk"), ("Test", "Hello, world!"))
  else:
    resp = fmtResponseHeader(STATUS_BAD_REQUEST, ("Server", "Silk"), ("Msg", "Ruh roh raggy!"))

  await client.send(resp)
  client.close()

proc serve(s: Server) {.async.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(s.port, s.host)
  server.listen()

  while true:
    if s.clients.len == s.maxClients:
      continue
    let client = await server.accept()
    s.clients.add(client)
    asyncCheck s.handleClient(client)

proc start*(s: Server) =
  asyncCheck s.serve()
  runForever()
