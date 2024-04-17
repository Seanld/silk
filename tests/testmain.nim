import std/asyncdispatch
import std/paths
from std/nativesockets import Port

import silk

var serv = newServer(host = "0.0.0.0", port = Port(8080))

proc helloPost(ctx: Context) {.async.} =
  if ctx.req.content[0..2] == "foo":
    await ctx.sendString("bar")
  else:
    await ctx.sendString("Wrong passphrase!")

serv.router.GET("/", proc(ctx: Context) {.async.} = await ctx.sendFile(Path("index.html"), "text/html"))
serv.router.GET("/test", proc(ctx: Context) {.async.} = await ctx.noContent(STATUS_OK))
serv.router.GET("/hello", proc(ctx: Context) {.async.} = await ctx.sendString("Hello, world!"))
serv.router.POST("/hello", helloPost)
# serv.router.defaultHandler = proc(ctx: Context) {.async.} = await ctx.noContent(STATUS_BAD_REQUEST)

serv.start()

# echo newResponseHeader(200, ("Test", "Hi"))
