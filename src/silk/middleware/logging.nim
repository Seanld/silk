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
  loggers: seq[Logger]

proc newLoggingMiddleware*(setting: LoggingMiddlewareSetting = lmsMinimal,
                           loggers: seq[Logger] = @[newConsoleLogger().Logger]): LoggingMiddleware =
  for l in loggers:
    addHandler(l)
  LoggingMiddleware(
    setting: setting,
    loggers: loggers,
  )

proc useLoggingMiddleware*(setting: LoggingMiddlewareSetting = lmsMinimal,
                           loggers: seq[Logger] = @[newConsoleLogger().Logger]): Middleware =
  newLoggingMiddleware(setting, loggers).Middleware

method processRequest*(m: LoggingMiddleware, req: Request): Request =
  result = req
  var msg = ""
  case m.setting:
    of lmsMinimal, lmsVerbose:
      msg = &"{req.remoteAddr} requested {$req.uri}"
  log(lvlInfo, msg)

method processResponse*(m: LoggingMiddleware, resp: Response): Response =
  resp
