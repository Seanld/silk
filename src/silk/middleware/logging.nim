# Logs requests to server's loggers.

import std/logging
import std/strformat
import std/tables
from std/uri import `$`

import ../middleware
import ../headers
import ../status

export logging

type MsgLoggingMiddlewareSetting* = enum
  lmsMinimal, lmsVerbose

type MsgLoggingMiddleware* = ref object of Middleware
  setting: MsgLoggingMiddlewareSetting

proc newMsgLoggingMiddleware*(setting: MsgLoggingMiddlewareSetting = lmsMinimal): MsgLoggingMiddleware =
  MsgLoggingMiddleware(setting: setting)

proc useMsgLoggingMiddleware*(setting: MsgLoggingMiddlewareSetting = lmsMinimal): Middleware =
  newMsgLoggingMiddleware(setting).Middleware

method processRequest*(m: MsgLoggingMiddleware, req: Request): Request =
  result = req
  var msg = ""
  case m.setting:
    of lmsMinimal, lmsVerbose:
      msg = &"-> {req.remoteAddr} requested {$req.uri}"
  info(msg)

method processResponse*(m: MsgLoggingMiddleware, resp: Response): Response =
  echo resp
  result = resp
  var msg = ""
  case m.setting:
    of lmsMinimal, lmsVerbose:
      let
        statusNum = resp.status.ord()
        statusName = STATUS_CODE_MAPPING[statusNum]
      msg = &"<- {statusName} {statusNum}"
  info(msg)
