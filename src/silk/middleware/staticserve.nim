# Handles serving static files from sandboxed directories. This is implementing
# on the middleware level to skip the complexity of tree routing, which should
# increase performance. Also, since it's separated from the core routing logic,
# more optimizations can be done without spaghettifying the core logic.

import std/paths
import std/asyncdispatch

import ../middleware
import ../headers
import ../context
import ../status

type StaticRouteTableInit = openArray[tuple[virtualPath: string, localPath: string]]
type StaticRouteTable = seq[tuple[virtualPath: string, localPath: string]]

type StaticMiddleware* = ref object of Middleware
  routes: StaticRouteTable

proc newStaticMiddleware*(routes: StaticRouteTableInit): StaticMiddleware =
  # Using table constructors (`{:}` syntax) makes this really finicky, so we
  # just copy the entries from the `array` to a new `seq`.
  var copiedRoutes: seq[tuple[virtualPath: string, localPath: string]]

  for i in 0 ..< routes.len:
    copiedRoutes.add((routes[i].virtualPath, routes[i].localPath))

  StaticMiddleware(
    routes: copiedRoutes,
  )

proc useStaticMiddleware*(routes: StaticRouteTableInit): Middleware =
  newStaticMiddleware(routes).Middleware

method processRequest*(m: StaticMiddleware, ctx: Context, req: Request): Future[ProcessingExitStatus] {.async.} =
  for route in m.routes:
    let sandboxDir = Path(route.virtualPath)
    if req.path.isRelativeTo(sandboxDir):
      let relPath = req.path.relativePath(sandboxDir)
      try:
        await ctx.sendFileAsync((Path(route.localPath) / relPath).string)
      except OSError:
        ctx.noContent(STATUS_NOT_FOUND)
      return SKIP_ROUTING
  return NORMAL

method processResponse*(m: StaticMiddleware, ctx: Context, resp: Response): Future[ProcessingExitStatus] {.async.} =
  discard
