import std/asyncnet
import std/asyncdispatch

var clients {.threadvar.}: seq[AsyncSocket]

proc handle(client: AsyncSocket) {.async.} =
  while true:
    let data = client.recv(1024)
    echo data

proc serve() {.async.} =
  clients = @[]
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(8080), "0.0.0.0")
  server.listen()

  while true:
    let client = await server.accept()
    clients.add(client)
    asyncCheck handle(client)

asyncCheck serve()
runForever()
