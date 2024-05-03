import std/tables
import std/asyncdispatch
import std/paths
from std/strutils import split, contains

import ./context
import ./headers
import ./middleware

type PathParams = TableRef[string, string]
type RouteHandler* = proc(ctx: Context) {.async.}
type RouterEntryHandle = tuple[handler: RouteHandler, middleware: seq[Middleware]]

template handler*(code: untyped): untyped =
  proc(ctx{.inject.}: Context) {.async.} = code

template handler*(name: untyped, code: untyped): untyped =
  proc name(ctx{.inject.}: Context) {.async.} = code

type Node = ref object
  part: string
  handle: RouterEntryHandle
  children: seq[Node]

proc newNode(part = "/", handle: RouterEntryHandle = (nil, @[]), children: seq[Node] = @[]): Node =
  Node(
    part: part,
    handle: handle,
    children: children,
  )

proc nodeString(n: Node, level: int): string =
  result = "<" & n.part & " " & repr(n.handle) & ">\n"
  for child in n.children:
    for i in 1..level:
      result &= " "
    result &= child.nodeString(level + 1)

proc `$`(n: Node): string =
  "-----\n" & n.nodeString(1) & "-----\n"

template debugStr(str: untyped): untyped =
  echo str.astToStr, ": `", str, "`"

proc lcp(a, b: string): string =
  ## Longest common prefix of two strings.
  for i in 0 ..< min(a.len, b.len):
    if a[i] == b[i]:
      result &= a[i]
      continue
    return

proc `$`*(p: Path): string =
  result = p.string
  if p.splitFile().ext == "" and result != "/":
    result &= "/"

proc search(n: Node, pathParts: seq[string], paramsDest: PathParams): tuple[node: Node, matched: bool, remainingParts: seq[string]] =
  let remainingParts = pathParts[1..^1]

  if paramsDest != nil and (n.part[0] == '{' and n.part[^1] == '}'):
    paramsDest[n.part[1..^2]] = pathParts[0]

  # Is the end of the given path, end recursion.
  if pathParts.len == 1 and n.handle.handler != nil:
    return (n, true, remainingParts)
  elif pathParts.len == 1 and n.handle.handler == nil:
    return (n, false, remainingParts)

  if pathParts.len > 1 and n.children.len > 0:
    # This node has children, and we still have more path to match.
    for child in n.children:
      if child.part == pathParts[1] or (child.part[0] == '{' and child.part[^1] == '}'):
        return child.search(remainingParts, paramsDest)

  # raise newException(RoutingError, "Could not match route")
  return (n, false, remainingParts)

proc search(n: Node, p: Path, paramsDest: PathParams): tuple[node: Node, matched: bool, remainingParts: seq[string]] =
  var
    parts: seq[string]
    pCopy = Path(p.string)

  pCopy.normalizePath()

  for part in pCopy.parentDirs(true, true):
    let asStr = part.lastPathPart.string
    parts.add(if asStr.len > 0: asStr else: "/")

  return n.search(parts, paramsDest)

proc insert(n: Node, p: Path, handler: RouterEntryHandle) =
  let results = n.search(p, nil)
  var parentNode = results.node
  for part in results.remainingParts:
    let newestNode = newNode(
      part = part,
    )
    parentNode.children.add(newestNode)
    parentNode = newestNode
  parentNode.handle = handler

type Router* = ref object
  routeTrees = {
    "GET": newNode(),
    "POST": newNode(),
    "PUT": newNode(),
    "DELETE": newNode(),
  }.toTable

proc newRouter*(): Router =
  Router()

proc registerHandlerRoute(r: Router, httpMethod: string, path: Path, handler: RouteHandler, middleware: seq[Middleware]) =
  r.routeTrees[httpMethod].insert(path, (handler, middleware))

proc GET*(r: Router, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  var newPath = Path(path)
  r.registerHandlerRoute("GET", newPath, handler, middleware)
proc POST*(r: Router, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  var newPath = Path(path)
  r.registerHandlerRoute("POST", newPath, handler, middleware)
proc PUT*(r: Router, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  var newPath = Path(path)
  r.registerHandlerRoute("PUT", newPath, handler, middleware)
proc DELETE*(r: Router, path: string, handler: RouteHandler, middleware: seq[Middleware] = @[]) =
  var newPath = Path(path)
  r.registerHandlerRoute("DELETE", newPath, handler, middleware)

type RoutingError = object of CatchableError

proc dispatchRoute*(r: Router, path: Path, ctx: Context) {.async.} =
  let searchResults = r.routeTrees[ctx.req.action].search(path, ctx.params)
  if searchResults.node == nil or not searchResults.matched:
    raise newException(RoutingError, "Could not match route")

  for mw in searchResults.node.handle.middleware:
    ctx.req = mw.processRequest(ctx.req)
  
  await searchResults.node.handle.handler(ctx)

  for mw in searchResults.node.handle.middleware:
    ctx.resp = mw.processResponse(ctx.resp)
