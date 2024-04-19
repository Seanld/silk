import std/asyncdispatch
import std/paths
import std/logging
from std/nativesockets import Port

import silk

var serv = newServer(
  ServerConfig(host: "0.0.0.0", port: Port(8080))
)
serv.loggers.add(newConsoleLogger())

serv.router.GET("/helloworld", proc(ctx: Context) {.async.} = ctx.sendString("Hello, world!"))

serv.start()
