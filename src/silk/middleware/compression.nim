import std/tables
import zippy

import ../middleware
import ../headers

type CompressionMiddleware* = ref object of Middleware
  discard

proc newCompressionMiddleware*(): CompressionMiddleware =
  CompressionMiddleware()

method processRequest*(m: CompressionMiddleware, req: Request): Request =
  req

method processResponse*(m: CompressionMiddleware, resp: Response): Response =
  resp.content = resp.content.compress(BestSpeed, dfGzip)
  resp.headerFields["Content-Encoding"] = "gzip"
  resp.headerFields["Content-Length"] = $resp.content.len
  return resp
