import std/tables
import std/asyncdispatch
import ./context
import ./status

type RouteHandler* = proc (ctx: Context) {.async.}
type RouteTable* = TableRef[string, RouteHandler]

# Even if the user of the library doesn't set their own `defaultHandler`,
# this handler will be used.
proc internalDefaultHandler(ctx: Context) {.async.} =
  await ctx.noContent(STATUS_BAD_REQUEST)

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

proc dispatchRoute*(r: Router, path: string, ctx: Context) {.async.} =
  try:
    await r.routes[path](ctx)
  except KeyError:
    if r.defaultHandler != nil:
      await r.defaultHandler(ctx)
    else:
      discard
