# Logs requests to server's loggers.

import std/logging
import std/strformat
import std/tables
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

method processRequest*(m: MsgLoggingMiddleware, ctx: Context, req: Request): ProcessingExitStatus {.gcsafe.} =
  case m.setting:
    of lmsMinimal, lmsVerbose:
      info(&"-> {req.remoteAddr} requested {$req.uri}")
  return ProcessingExitStatus.NORMAL

method processResponse*(m: MsgLoggingMiddleware, ctx: Context, resp: Response): ProcessingExitStatus {.gcsafe.} =
  case m.setting:
    of lmsMinimal, lmsVerbose:
      let
        statusNum = resp.status.ord()
        statusName = STATUS_CODE_MAPPING[statusNum]
      info(&"<- {statusName} {statusNum}")
  return ProcessingExitStatus.NORMAL
