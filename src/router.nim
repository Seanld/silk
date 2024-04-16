import std/tables
import std/asyncdispatch
import ./context
import ./headers
import ./status

type RouteHandler* = proc (ctx: Context) {.async.}
type RouteTable* = TableRef[string, RouteHandler]

# Even if the user of the library doesn't set their own `defaultHandler`,
# this handler will be used.
proc internalDefaultHandler(ctx: Context) {.async.} =
  await ctx.noContent(STATUS_NOT_FOUND)

type Router* = object
  routes: RouteTable

  # Called when no routes were matched.
  defaultHandler* = internalDefaultHandler

proc newRouter*(routeTable: RouteTable = nil): Router =
  var table: RouteTable

  if routeTable != nil:
    table = routeTable
  else:
    table = newTable[string, RouteHandler]()

  return Router(
    routes: table,
  )

proc GET*(r: Router, path: string, handler: RouteHandler) =
  r.routes["GET: " & path] = handler
proc POST*(r: Router, path: string, handler: RouteHandler) =
  r.routes["POST: " & path] = handler
proc PUT*(r: Router, path: string, handler: RouteHandler) =
  r.routes["PUT: " & path] = handler
proc DELETE*(r: Router, path: string, handler: RouteHandler) =
  r.routes["DELETE: " & path] = handler

proc dispatchRoute*(r: Router, req: Request, ctx: Context) {.async.} =
  try:
    await r.routes[req.action & ": " & req.path](ctx)
  except KeyError:
    if r.defaultHandler != nil:
      await r.defaultHandler(ctx)
    else:
      discard
