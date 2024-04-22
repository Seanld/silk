import std/asyncnet
import std/tables
import std/paths
import std/mimetypes

import ./headers
import ./status

type Context* = ref object
  conn*: AsyncSocket
  req*: Request
  resp*: Response
  params*: Table[string, string]

proc newContext*(conn: AsyncSocket, req: Request): Context =
  return Context(
    conn: conn,
    req: req,
    params: initTable[string, string](),
  )

proc noContent*(ctx: Context, status: StatusCode) =
  ctx.resp = newResponse(status)

proc sendString*(ctx: Context, str: string, mime: string = "text/plain", status: StatusCode = STATUS_OK) =
  let resp = newResponse(status, content = str)
  resp.headerFields["Content-Type"] = mime & "; charset=utf-8"
  resp.headerFields["Content-Length"] = $str.len
  ctx.resp = resp

proc sendFile*(ctx: Context, path: Path, mime: string = "", status: StatusCode = STATUS_OK) =
  ## `mime` can be left empty, and mimetype will be recognized
  ## based on file extension, if a file extension exists. Otherwise
  ## an exception will be raised.
  let m = newMimetypes()
  var actualMime = ""
  if mime != "":
    actualMime = mime
  else:
    let (_, _, ext) = path.splitFile()
    if ext == "":
      raise newException(Exception, "Mimetype required for sendFile (not given or found)")
    actualMime = m.getMimetype(ext)
  ctx.sendString(readFile(path.string), actualMime, status)
