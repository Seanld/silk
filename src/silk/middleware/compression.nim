import std/tables
import std/asyncdispatch
import zippy

import ../middleware
import ../headers
import ../context

export CompressedDataFormat

type CompressionMiddleware* = ref object of Middleware
  level: int
  format: CompressedDataFormat

const FORMAT_MAPPING = {
  dfGzip: "gzip",
  dfDeflate: "deflate",
  dfZlib: "zlib",
}.toTable

proc newCompressionMiddleware*(level: int = BestSpeed, format: CompressedDataFormat = dfGzip): CompressionMiddleware =
  CompressionMiddleware(
    level: level,
    format: format,
  )

proc useCompressionMiddleware*(level: int = BestSpeed, format: CompressedDataFormat = dfGzip): Middleware =
  newCompressionMiddleware(level, format).Middleware

method processRequest*(m: CompressionMiddleware, ctx: Context, req: Request): Future[ProcessingExitStatus] {.async, gcsafe.} =
  discard

method processResponse*(m: CompressionMiddleware, ctx: Context, resp: Response): Future[ProcessingExitStatus] {.async, gcsafe.} =
  resp.content = resp.content.compress(m.level, m.format)
  resp.headerFields["Content-Encoding"] = FORMAT_MAPPING[m.format]
  resp.headerFields["Content-Length"] = $resp.content.len
