import std/tables
import std/asyncdispatch
import std/paths
import ./context
import ./headers
import ./status

type RouteHandler* = proc (ctx: Context) {.async.}
type RouteTableEntry* = tuple[action: string, path: string]
type HandlerTable* = TableRef[RouteTableEntry, RouteHandler]
type StaticSeqEntry* = tuple[rootPath: string, localDir: string]
type StaticSeq* = seq[StaticSeqEntry]

# Even if the user of the library doesn't set their own `defaultHandler`,
# this handler will be used.
proc internalDefaultHandler(ctx: Context) {.async.} =
  await ctx.noContent(STATUS_NOT_FOUND)

type Router* = object
  handlerRoutes: HandlerTable
  staticRoutes: StaticSeq

  # Called when no routes were matched.
  defaultHandler* = internalDefaultHandler

proc newRouter*(handlerRoutes: HandlerTable = nil): Router =
  var
    newHandlerRouteTable: HandlerTable

  if handlerRoutes != nil:
    newHandlerRouteTable = handlerRoutes
  else:
    newHandlerRouteTable = newTable[RouteTableEntry, RouteHandler]()

  return Router(
    handlerRoutes: newHandlerRouteTable,
    staticRoutes: newSeq[StaticSeqEntry](),
  )

proc GET*(r: Router, path: string, handler: RouteHandler) =
  r.handlerRoutes[("GET", path)] = handler
proc POST*(r: Router, path: string, handler: RouteHandler) =
  r.handlerRoutes[("POST", path)] = handler
proc PUT*(r: Router, path: string, handler: RouteHandler) =
  r.handlerRoutes[("PUT", path)] = handler
proc DELETE*(r: Router, path: string, handler: RouteHandler) =
  r.handlerRoutes[("DELETE", path)] = handler

# Any files underneath `rootPath` will be served when requested via GET.
proc static*(r: var Router, rootPath: string, localDir: string) =
  r.staticRoutes.add((rootPath, localDir))

# proc respondStatic(ctx: Context) {.async.} =
#   ## Send static file response.
#   discard

proc dispatchRoute*(r: Router, req: Request, ctx: Context) {.async.} =
  try:
    await r.handlerRoutes[(req.action, req.path.string)](ctx)
  except KeyError:
    discard

  for entry in r.staticRoutes:
    let rootPathAsPath = Path(entry.rootPath)
    if req.path.isRelativeTo(rootPathAsPath):
      # TODO: figure out how to uniformly respond in the middle of routing for static files.
      discard

  # Didn't match request to any route entry. Use default handler.
  if r.defaultHandler != nil:
    await r.defaultHandler(ctx)
  else:
    discard
