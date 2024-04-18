import std/asyncdispatch
import std/paths
from std/nativesockets import Port

import silk

var serv = newServer("0.0.0.0", Port(8080))

# serv.router.GET("/", proc(ctx: Context) {.async.} = ctx.sendFile(Path("index.html"), "text/html"))
# serv.router.GET("/test", proc(ctx: Context) {.async.} = ctx.noContent(STATUS_OK))
# serv.router.GET("/hello", proc(ctx: Context) {.async.} = ctx.sendString("Hello, world!"))
# serv.router.POST("/hello", helloPost)
# serv.router.defaultHandler = proc(ctx: Context) {.async.} = await ctx.noContent(STATUS_BAD_REQUEST)
serv.router.GET("/helloworld", proc(ctx: Context) {.async.} = ctx.sendString("Hello, world!"))

serv.start()

# echo newResponseHeader(200, ("Test", "Hi"))
