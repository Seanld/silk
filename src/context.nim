import std/asyncdispatch
import std/asyncnet
import std/tables

import ./headers
import ./status

type Context* = object
  conn: AsyncSocket

proc newContext*(conn: AsyncSocket): Context =
  return Context(
    conn: conn,
  )

proc noContent*(ctx: Context, status: StatusCode) {.async.} =
  let resp = $newResponseHeader(status)
  await ctx.conn.send(resp)

proc sendString*(ctx: Context, str: string, mime: string = "text/plain", status: StatusCode = STATUS_OK) {.async.} =
  let resp = newResponseHeader(status, content = str)
  resp.headerFields["Content-Type"] = mime & "; charset=utf-8"
  await ctx.conn.send($resp)
