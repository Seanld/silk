# Logs requests to server's loggers.

import std/logging
import std/strformat
from std/uri import `$`

import ../middleware
import ../headers

export logging

type LoggingMiddlewareSetting* = enum
  lmsMinimal, lmsVerbose

type LoggingMiddleware* = ref object of Middleware
  setting: LoggingMiddlewareSetting

proc newLoggingMiddleware*(setting: LoggingMiddlewareSetting = lmsMinimal): LoggingMiddleware =
  LoggingMiddleware(setting: setting)

proc useLoggingMiddleware*(setting: LoggingMiddlewareSetting = lmsMinimal): Middleware =
  newLoggingMiddleware(setting).Middleware

method processRequest*(m: LoggingMiddleware, req: Request): Request =
  result = req
  var msg = ""
  case m.setting:
    of lmsMinimal, lmsVerbose:
      msg = &"{req.remoteAddr} requested {$req.uri}"
  info(msg)

method processResponse*(m: LoggingMiddleware, resp: Response): Response =
  resp