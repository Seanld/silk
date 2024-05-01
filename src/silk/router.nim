import std/tables
import std/asyncdispatch
import std/paths
import std/algorithm
from std/sequtils import zip, toSeq
from std/strutils import split, contains

import ./context
import ./headers
import ./status
import ./middleware

type NodeParam = tuple[idx: int, name: string]
type RouteHandler* = proc(ctx: Context) {.async.}
type RouterEntryHandle = tuple[handler: RouteHandler, middleware: seq[Middleware], params: seq[NodeParam]]

template handler*(code: untyped): untyped =
  proc(ctx{.inject.}: Context) {.async.} = code

template handler*(name: untyped, code: untyped): untyped =
  proc name(ctx{.inject.}: Context) {.async.} = code

type Handler = proc(): void

type Node = ref object
  part: string
  handle: RouterEntryHandle
  children: seq[Node]

proc newNode(part = "/", handle: RouterEntryHandle = (nil, @[], @[]), children: seq[Node] = @[]): Node =
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
  "-----\n" & n.nodeString(1) & "\n-----"

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

type FindResult = tuple[node: Node, prefix: string, remainder: string, matched: bool]

proc traverse(n: Node, key: string): FindResult =
  let prefix = lcp(n.part, key)
  if prefix.len > 0:
    # There was a common prefix (partial or full).
    if prefix.len == key.len and prefix.len == n.part.len:
      # Full key matched.
      return (n, prefix, key, n.handle.handler != nil)
    else:
      # Key was only partially matched. Attempt further matching on children.
      let remaining = key[prefix.len..^1]
      if n.children.len == 0:
        return (n, prefix, key, false)
      for child in n.children:
        let next = child.traverse(remaining)
        if next.node != nil:
          return next
  return (nil, prefix, key, false)

proc normalizePathStrParams(p: Path): Path =
  var
    newPathStr: string
    inParam = false
  for c in p.string:
    if not inParam:
      newPathStr &= c
    if c == '{':
      inParam = true
      continue
    elif c == '}':
      inParam = false
      continue
  return Path(newPathStr)

proc find(n: Node, keyPath: Path): RouterEntryHandle =
  let
    key = $keyPath
    (travNode, _, _, travMatched) = n.traverse(key)
  if travMatched:
    return travNode.handle
  else:
    raise newException(KeyError, "Key does not exist in route tree")

proc insert(n: Node, keyPath: Path, handler: RouterEntryHandle) =
  let
    key = $keyPath
    (foundNode, prefix, remainder, matched) = n.traverse(key)

  if foundNode != nil:
    if matched:
      raise newException(KeyError, "Key already exists in route tree")

    if prefix == foundNode.part and prefix == key:
      foundNode.handle = handler
      return

    else:
      if prefix.len < foundNode.part.len:
        foundNode.children.add(newNode(
          foundNode.part[prefix.len..^1],
          handle = foundNode.handle
        ))
        foundNode.part = prefix
        foundNode.handle = (nil, @[], @[])

      foundNode.children.add(newNode(
        remainder[prefix.len..^1],
        handle = handler
      ))

type Router* = ref object
  routeTrees = {
    "GET": newNode(),
    "POST": newNode(),
    "PUT": newNode(),
    "DELETE": newNode(),
  }.toTable

proc newRouter*(): Router =
  Router()

proc registerHandlerRoute(r: Router, httpMethod: string, path: var Path, handler: RouteHandler, middleware: seq[Middleware]) =
  path.normalizePath()

  # Parse URL path params
  var
    i = 0
    params: seq[NodeParam]

  for parentDir in path.parentDirs:
    let part = parentDir.lastPathPart().string
    if part.len > 2 and part[0] == '{' and part[^1] == '}':
      params.add((idx: i, name: part[1..^2]))
    i += 1

  r.routeTrees[httpMethod].insert(path, (handler, middleware, params))
  # echo r.routeTrees[httpMethod]

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

proc dispatchRoute*(r: Router, path: Path, ctx: Context) {.async.} =
  let (matchedRouteHandler, matchedRouteMiddleware, matchedRouteParams) = r.routeTrees[ctx.req.action].find(path)

  # Parse URL path params
  var paramTable: Table[string, string]
  for routeParam in matchedRouteParams:
    var tempPath = Path(path.string)
    for n in 0 ..< routeParam.idx:
      tempPath = tempPath.parentDir()
    let last = tempPath.lastPathPart()
    paramTable[routeParam.name] = last.string

  ctx.params = paramTable

  for mw in matchedRouteMiddleware:
    ctx.req = mw.processRequest(ctx.req)
  
  await matchedRouteHandler(ctx)

  for mw in matchedRouteMiddleware:
    ctx.resp = mw.processResponse(ctx.resp)
