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

type RouteHandler* = proc(ctx: Context) {.async.}
type RouterEntryHandle = tuple[handler: RouteHandler, middleware: seq[Middleware]]

template handler*(code: untyped): untyped =
  proc(ctx{.inject.}: Context) {.async.} = code

template handler*(name: untyped, code: untyped): untyped =
  proc name(ctx{.inject.}: Context) {.async.} = code

type Handler = proc(): void

type Node = ref object
  part: string
  handle: Handler
  children: seq[Node]

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

proc newNode(part = "/", handle: Handler = nil, children: seq[Node] = @[]): Node =
  Node(
    part: part,
    handle: handle,
    children: children,
  )

proc lcp(a, b: string): string =
  ## Longest common prefix of two strings.
  for i in 0 ..< min(a.len, b.len):
    if a[i] == b[i]:
      result &= a[i]
      continue
    return

type FindResult = tuple[node: Node, prefix: string, remainder: string, matched: bool]

proc traverse(n: Node, key: string): FindResult =
  let prefix = lcp(n.part, key)
  if prefix.len > 0:
    # There was a common prefix (partial or full).
    if prefix.len == key.len and prefix.len == n.part.len:
      # Full key matched.
      return (n, prefix, key, n.handle != nil)
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

proc find(n: Node, key: string): Handler =
  let (travNode, _, _, travMatched) = n.traverse(key)
  if travMatched:
    return travNode.handle
  else:
    raise newException(KeyError, "Key does not exist in route tree")

proc insert(n: Node, key: string, handler: Handler) =
  let (foundNode, prefix, remainder, matched) = n.traverse(key)
  if foundNode != nil:
    if matched:
      raise newException(KeyError, "Key already exists in route tree")
    if prefix == foundNode.part:
      foundNode.handle = handler
      return
    else:
      debugStr prefix
      foundNode.children.add(newNode(
        foundNode.part[prefix.len..^1],
        handle = foundNode.handle
      ))
      foundNode.part = prefix
      foundNode.handle = nil
      foundNode.children.add(newNode(
        remainder[prefix.len..^1],
        handle = handler
      ))

type Router* = ref object
  routeTrees = {
    "GET": newNode,
    "POST": newNode,
    "PUT": newNode,
    "DELETE": newNode,
  }.toTable
