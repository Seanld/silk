import std/asyncdispatch
import std/logging
import std/tables
import std/paths
from std/nativesockets import Port

import silk
import silk/middleware/compression

var serv = newServer(
  ServerConfig(host: "0.0.0.0", port: Port(8080))
)

serv.addLogger(newConsoleLogger())

proc getImg(ctx: Context) {.async.} =
  let filename = ctx.params["filename"]
  try:
    ctx.sendFile((Path("./tests/img/") / Path(filename)).string)
  except:
    ctx.sendString("File does not exist!", status = STATUS_INTERNAL_SERVER_ERROR)

serv.GET("/helloworld", ~> ctx.sendString("Hello, world!"))
serv.GET("/user/{username}/post/{id}", ~> ctx.sendString("Viewing post #" & ctx.params["id"] & " from user '" & ctx.params["username"] & "'"))
serv.GET("/img/{filename}", getImg, @[useCompressionMiddleware()])

serv.start()
