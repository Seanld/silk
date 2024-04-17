import std/asyncdispatch
import std/asyncnet
import std/tables
import std/paths

import ./headers
import ./status

type Context* = object
  conn*: AsyncSocket
  req*: Request

proc newContext*(conn: AsyncSocket, req: Request): Context =
  return Context(
    conn: conn,
    req: req,
  )

proc noContent*(ctx: Context, status: StatusCode) {.async.} =
  let resp = $newResponseHeader(status)
  await ctx.conn.send(resp)

proc sendString*(ctx: Context, str: string, mime: string = "text/plain", status: StatusCode = STATUS_OK) {.async.} =
  let resp = newResponseHeader(status, content = str)
  resp.headerFields["Content-Type"] = mime & "; charset=utf-8"
  resp.headerFields["Content-Length"] = $str.len
  await ctx.conn.send($resp)

proc sendFile*(ctx: Context, path: Path, mime: string, status: StatusCode = STATUS_OK) {.async.} =
  await ctx.sendString(readFile(path.string), mime, status)
