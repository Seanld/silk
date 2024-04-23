import std/paths
from std/strutils import parseBool

import silk
import silk/middleware/compression
import silk/middleware/logging

var serv = newServer(
  ServerConfig(host: "0.0.0.0", port: Port(8080))
)

serv.addMiddleware(newLoggingMiddleware())

proc getImg(ctx: Context) {.async.} =
  let filename = ctx.params["filename"]
  try:
    ctx.sendFile((Path("./tests/img/") / Path(filename)).string)
  except:
    ctx.sendString("File does not exist!", status = STATUS_INTERNAL_SERVER_ERROR)

proc viewPost(ctx: Context) {.async.} =
  let query = ctx.parseQuery()
  let silent = try: parseBool(query["s"]) except: false
  if not silent:
    ctx.sendString("Viewing post #" & ctx.params["id"] & " from user '" & ctx.params["username"] & "'")
  else:
    ctx.sendString("Viewing post")

serv.GET("/helloworld", ~> ctx.sendString("Hello, world!"))
serv.GET("/user/{username}/post/{id}", viewPost)
serv.GET("/img/{filename}", getImg, @[useCompressionMiddleware()])

serv.start()
