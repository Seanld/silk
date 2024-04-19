import zippy

import ./base
import ../headers

export base

type CompressionMiddleware* = ref object
  discard

proc newCompressionMiddleware*(): CompressionMiddleware =
  CompressionMiddleware()

proc processRequest*(m: CompressionMiddleware, req: Request): Request =
  req

proc processResponse*(m: CompressionMiddleware, resp: Response): Response =
  resp.content = resp.content.compress(BestSpeed, dfGzip)
  resp.headerFields["Content-Encoding"] = "gzip"
  return resp
