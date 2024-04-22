import std/asyncdispatch
import std/paths
import std/logging
import std/tables
from std/nativesockets import Port

import silk
import silk/middleware/compression

var serv = newServer(
  ServerConfig(host: "0.0.0.0", port: Port(8080))
)
serv.loggers.add(newConsoleLogger())

# serv.addMiddleware(newCompressionMiddleware())

serv.router.GET("/helloworld", proc(ctx: Context) {.async.} = ctx.sendString("Hello, world!"))
serv.router.GET("/user/{username}/post/{id}", proc(ctx: Context) {.async.} = ctx.sendString("Viewing post #" & ctx.params["id"] & " from user '" & ctx.params["username"] & "'"))

serv.start()
