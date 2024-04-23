import std/tables
import std/asyncdispatch
import std/paths
from std/sequtils import zip, toSeq
from std/strutils import split

import ./context
import ./headers
import ./status
import ./middleware

type RouteHandler* = proc (ctx: Context) {.async.}
type HandlerEntryVal* = tuple[handler: RouteHandler, middleware: seq[Middleware]]
type RouteTableEntry* = tuple[action: string, path: string]
type HandlerTable* = TableRef[RouteTableEntry, HandlerEntryVal]
type StaticSeqEntry* = tuple[rootPath: string, localDir: string]
type StaticSeq* = seq[StaticSeqEntry]

# Even if the user of the library doesn't set their own `defaultHandler`,
# this handler will be used.
proc internalDefaultHandler(ctx: Context) =
  ctx.noContent(STATUS_NOT_FOUND)

type Router* = ref object
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
    newHandlerRouteTable = newTable[RouteTableEntry, HandlerEntryVal]()

  return Router(
    handlerRoutes: newHandlerRouteTable,
    staticRoutes: newSeq[StaticSeqEntry](),
  )

proc registerHandlerRoute(r: Router, methodStr: string, path: string, handler: RouteHandler, middleware: seq[Middleware]) =
  var normalizedPath = Path(path); normalizedPath.normalizePath()
  r.handlerRoutes[(methodStr, normalizedPath.string)] = (handler: handler, middleware: middleware)
  for mw in middleware:
    mw.init()

proc GET*(r: Router, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  registerHandlerRoute(r, "GET", path, handler, middleware)
proc POST*(r: Router, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  registerHandlerRoute(r, "POST", path, handler, middleware)
proc PUT*(r: Router, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  registerHandlerRoute(r, "PUT", path, handler, middleware)
proc DELETE*(r: Router, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  registerHandlerRoute(r, "DELETE", path, handler, middleware)

# Any files underneath `rootPath` will be served when requested via GET.
proc staticDir*(r: Router, rootPath: string, localDir: string) =
  r.staticRoutes.add((rootPath, localDir))

proc matchHandlerRoute(r: Router, req: Request, ctx: Context): HandlerEntryVal =
  # This may later be optimized by sorting entries into groups
  # based on their path length, which can reduce the amount of
  # wasted path comparisons, especially for routers with many entries.
  for entry, entryVal in r.handlerRoutes:
    let (handler, middleware) = entryVal
    block outer:
      let
        entryPathLength = entry.path.split("/").len - 1
        reqPathLength = req.path.string.split("/").len - 1

      if entryPathLength == reqPathLength:
        let zipped: seq[tuple[entryPathPart, reqPathPart: Path]] =
          zip(Path(entry.path).parentDirs.toSeq, req.path.parentDirs.toSeq)

        for parts in zipped:
          let
            entryPathTail = parts.entryPathPart.splitPath().tail
            reqPathTail = parts.reqPathPart.splitPath().tail

          if entryPathTail.string.len > 1 and entryPathTail.string[0] == '{' and entryPathTail.string[^1] == '}':
            ctx.params[entryPathTail.string[1..^2]] = reqPathTail.string
          elif entryPathTail != reqPathTail:
            break outer

        return (handler, middleware)

proc dispatchRoute*(r: Router, req: Request, ctx: Context) {.async.} =
  ## Calls the appropriate handler proc, or gets content of
  ## statically-routed file if appropriate, and updates `ctx.resp`
  ## with the resulting response.

  let (handlerRoute, handlerMiddleware) = matchHandlerRoute(r, req, ctx)
  if handlerRoute != nil:
    for mw in handlerMiddleware:
      ctx.req = mw.processRequest(req)
    await handlerRoute(ctx)
    for mw in handlerMiddleware:
      ctx.resp = mw.processResponse(ctx.resp)
    return

  # Check for static route match.
  for entry in r.staticRoutes:
    let rootPathAsPath = Path(entry.rootPath)
    if req.path.isRelativeTo(rootPathAsPath):
      let
        relPath = req.path.relativePath(rootPathAsPath)
        localPath = Path(entry.localDir) / relPath
      ctx.sendFile(localPath.string)
      return

  # Didn't match request to any route entry. Use default handler.
  if r.defaultHandler != nil:
    r.defaultHandler(ctx)
  else:
    raise newException(Exception, "No route matched, and default handler not set")
