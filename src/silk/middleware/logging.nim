# Logs requests to server's loggers.

import std/logging
import std/strformat
import std/tables
import std/asyncdispatch
from std/uri import `$`

import ../middleware
import ../headers
import ../status
import ../context

export logging

type MsgLoggingMiddlewareSetting* = enum
  lmsMinimal, lmsVerbose

type MsgLoggingMiddleware* = ref object of Middleware
  setting: MsgLoggingMiddlewareSetting

proc newMsgLoggingMiddleware*(setting: MsgLoggingMiddlewareSetting = lmsMinimal): MsgLoggingMiddleware =
  MsgLoggingMiddleware(setting: setting)

proc useMsgLoggingMiddleware*(setting: MsgLoggingMiddlewareSetting = lmsMinimal): Middleware =
  newMsgLoggingMiddleware(setting).Middleware

method processRequest*(m: MsgLoggingMiddleware, ctx: Context, req: Request): Future[ProcessingExitStatus] {.async, gcsafe.} =
  var msg = ""
  case m.setting:
    of lmsMinimal, lmsVerbose:
      msg = &"-> {req.remoteAddr} requested {$req.uri}"
  info(msg)

method processResponse*(m: MsgLoggingMiddleware, ctx: Context, resp: Response): Future[ProcessingExitStatus] {.async, gcsafe.} =
  var msg = ""
  case m.setting:
    of lmsMinimal, lmsVerbose:
      let
        statusNum = resp.status.ord()
        statusName = STATUS_CODE_MAPPING[statusNum]
      msg = &"<- {statusName} {statusNum}"
  info(msg)
