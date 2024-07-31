import std/paths
import std/strutils

when compileOption("profiler"):
  import std/nimprof

import silk
import silk/middleware/compression
import silk/middleware/logging
import silk/middleware/staticserve

var sl = newServerLogger(
  @[newRollingFileLogger("test.log", maxLines = 20000).Logger],
)

var serv = newServer(
  ServerConfig(
    host: "0.0.0.0",
    port: Port(8080),
    workers: 4,
    serverLogger: sl,
  ),
  middleware = @[
    useStaticMiddleware({
      "/img": "./tests/img",
    }),
    useMsgLoggingMiddleware(sl),
  ],
)

serv.GET("/", handler do: ctx.sendFile Path("./tests/index.html").string)
serv.GET("/", "./tests/index.html")
serv.POST(
  "/",
  handler do:
    let q = ctx.parseFormQuery()
    try:
      ctx.sendString "Registering '$1' with email '$2'" % [q["uname"], q["uemail"]]
    except:
      ctx.sendString "Failed to parse query. Might be missing fields."
)

serv.GET("/hello/world", handler do: ctx.sendString "Hello, world!")
serv.GET("/howdy", handler do: ctx.sendString "Howdy there")
serv.GET("/hello/there/", handler do: ctx.sendString "General Kenobi!")
serv.GET("/hello/{blahparam}/wompus/", handler do: ctx.sendString "what is up " & ctx.params["blahparam"])
serv.GET(
  "/user/{username}/post/{id}",
  handler do:
    let query = ctx.parseQuery()
    let silent = try: parseBool(query["s"]) except: false
    if not silent:
      ctx.sendString "Viewing post #" & ctx.params["id"] & " from user '" & ctx.params["username"] & "'"
    else:
      ctx.sendString "Viewing post"
)
serv.GET("/hello/{blahparam}/wompus/test", handler do: ctx.sendString "yo mama")

proc isPrime(num: int): bool =
  for n in 2 ..< num - 1:
    if num mod n == 0:
      return false
  return true

serv.GET(
  "/isprime/{number}",
  handler do:
    let number = parseInt(ctx.params["number"])
    if isPrime(number):
      ctx.noContent(STATUS_OK)
    else:
      ctx.noContent(STATUS_INTERNAL_SERVER_ERROR)
)

when compileOption("profiler"):
  enableProfiling()

  proc ctrlc() {.noconv.} =
    disableProfiling()
    quit()

  setControlCHook(ctrlc)

serv.start()
