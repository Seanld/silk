# Logs requests to server's loggers.

import std/strformat
import std/tables
from std/net import getPeerAddr
from std/logging import Level
from std/uri import `$`

import ../middleware
import ../headers
import ../status
import ../context
import ../serverlogger

export logging
export serverlogger

type MsgLoggingMiddlewareSetting* = enum
  lmsMinimal, lmsVerbose

type MsgLoggingMiddleware* = ref object of Middleware
  serverLogger: ServerLogger
  setting: MsgLoggingMiddlewareSetting

proc newMsgLoggingMiddleware*(serverLogger: ServerLogger,
                              setting: MsgLoggingMiddlewareSetting = lmsMinimal): MsgLoggingMiddleware =
  MsgLoggingMiddleware(serverLogger: serverLogger, setting: setting)

proc useMsgLoggingMiddleware*(serverLogger: ServerLogger,
                              setting: MsgLoggingMiddlewareSetting = lmsMinimal): Middleware =
  newMsgLoggingMiddleware(serverLogger, setting).Middleware

method processRequest*(m: MsgLoggingMiddleware,
                       ctx: Context,
                       req: Request): ProcessingExitStatus {.gcsafe.} =
  let remotePort = int(req.remotePort)
  case m.setting:
    of lmsMinimal, lmsVerbose:
      m.serverLogger.log(&"{req.remoteAddr}:{remotePort} -> {$req.uri}", lvlInfo)
  return ProcessingExitStatus.NORMAL

method processResponse*(m: MsgLoggingMiddleware,
                        ctx: Context,
                        resp: Response): ProcessingExitStatus {.gcsafe.} =
  case m.setting:
    of lmsMinimal, lmsVerbose:
      let
        statusNum = resp.status.ord()
        statusName = STATUS_CODE_MAPPING[statusNum]
        requesteeAddress = ctx.req.remoteAddr
        requesteePort = int(ctx.req.remotePort)
      m.serverLogger.log(&"{requesteeAddress}:{requesteePort} <- {statusNum} {statusName}", lvlInfo)
  return ProcessingExitStatus.NORMAL
