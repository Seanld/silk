import std/paths
import std/logging
import std/strutils
from std/strutils import parseBool

when compileOption("profiler"):
  import std/nimprof

import silk
import silk/middleware/compression
import silk/middleware/logging

var serv = newServer(
  ServerConfig(host: "0.0.0.0", port: Port(8080)),
  @[newFileLogger("log.txt").Logger],
)

# handler getImg:
#   let filename = ctx.params["filename"]
#   try:
#     ctx.sendFile (Path("./tests/img/") / Path(filename)).string
#   except:
#     ctx.sendString "File does not exist!", status = STATUS_INTERNAL_SERVER_ERROR

# serv.GET("/", handler do: ctx.sendFile Path("./tests/index.html").string)
# serv.POST(
#   "/",
#   handler do:
#     let q = ctx.parseFormQuery()
#     try:
#       ctx.sendString "Registering '$1' with email '$2'" % [q["uname"], q["uemail"]]
#     except:
#       ctx.sendString "Failed to parse query. Might be missing fields."
# )

# serv.GET("/helloworld", handler do: ctx.sendString "Hello, world!")
# serv.GET(
#   "/user/{username}/post/{id}",
#   handler do:
#     let query = ctx.parseQuery()
#     let silent = try: parseBool(query["s"]) except: false
#     if not silent:
#       ctx.sendString "Viewing post #" & ctx.params["id"] & " from user '" & ctx.params["username"] & "'"
#     else:
#       ctx.sendString "Viewing post"
# )
# serv.GET("/img/{filename}", getImg, @[useCompressionMiddleware()])


# when compileOption("profiler"):
#   enableProfiling()

#   proc ctrlc() {.noconv.} =
#     disableProfiling()
#     quit()

#   setControlCHook(ctrlc)

# serv.start()

var router = Router()
router.compileRoutes()
