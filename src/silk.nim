import std/asyncnet
import std/asyncdispatch
import std/tables
import std/strutils
include ./status
include ./headers

proc handleClient(client: AsyncSocket) {.async.} =
  var
    reqHeader = (await client.recvReqHeader()).parseReqHeader()
    resp = ""

  if reqHeader.path == "/test":
    resp = newResponseHeader(200, ("Server", "Silk"), ("Test", "Hello, world!"))
  else:
    resp = newResponseHeader(400, ("Server", "Silk"), ("Msg", "Ruh roh raggy!"))

  await client.send(resp)
  client.close()

type Server* = object
  host*: string
  port*: Port
  maxClients*: uint64 = 100

proc serve(s: Server) {.async.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(s.port, s.host)
  server.listen()

  while true:
    let client = await server.accept()
    asyncCheck handleClient(client)

proc start*(s: Server) =
  asyncCheck s.serve()
  runForever()
