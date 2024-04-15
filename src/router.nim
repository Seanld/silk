import std/tables
import std/asyncdispatch
import ./context

type RouteHandler* = proc (ctx: Context) {.async.}
type RouteTable* = TableRef[string, RouteHandler]

type Router* = object
  routes: RouteTable

  # Called when no routes were matched.
  defaultHandler*: RouteHandler

proc newRouter*(routeTable: RouteTable = nil): Router =
  var table: RouteTable

  if routeTable != nil:
    table = routeTable
  else:
    table = newTable[string, RouteHandler]()

  return Router(
    routes: table,
  )

proc addRoute*(r: Router, path: string, handler: RouteHandler) =
  r.routes[path] = handler

proc handleRoute*(r: Router, path: string, ctx: Context) {.async.} =
  try:
    await r.routes[path](ctx)
  except KeyError:
    await r.defaultHandler(ctx)
