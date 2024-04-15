import std/asyncdispatch
import std/asyncnet

import ./headers
import ./status

type Context* = object
  conn: AsyncSocket

proc newContext*(conn: AsyncSocket): Context =
  return Context(
    conn: conn,
  )

proc noContent*(ctx: Context, status: StatusCode) {.async.} =
  let resp = newResponse(status)
  await ctx.conn.send(resp)
