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
type RouterEntry = tuple[httpMethod: string, path: string, handle: RouterEntryHandle]

template handler*(code: untyped): untyped =
  proc(ctx{.inject.}: Context) {.async.} = code

template handler*(name: untyped, code: untyped): untyped =
  proc name(ctx{.inject.}: Context) {.async.} = code

type Node = ref object
  part: string
  handle: RouterEntryHandle
  children: seq[Node]

proc treeInsert(rootNode: Node, newNode: Node) =
  for child in rootNode.children:
    # TODO Implement radix tree insertion (longest common prefix)
    discard

type Router* = ref object
  routeTrees = {
    "GET": Node("/"),
    "POST": Node("/"),
    "PUT": Node("/"),
    "DELETE": Node("/"),
  }.toTable
