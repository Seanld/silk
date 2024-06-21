import std/logging

type LogItem* = object
  msg: string
  lvl: Level

type ServerLogger* = ref object
  ## All `Logger` objects that will be logged to.
  loggers*: seq[Logger]

  ## The global log filter level. Only log messages
  ## with a level equal to, or higher than, this will
  ## be logged.
  logFilter*: Level

  ## Channel that acts as a queue for log messages that
  ## need to be handled in order, from multiple threads.
  logQueue*: Channel[LogItem]

# Even though it seems unintuitive to have such a useless
# constructor, the compiler complains about the channel if
# it's not done this way.
proc newServerLogger*(loggers = @[newConsoleLogger().Logger],
                      logFilter = lvlInfo,
                      logQueue = Channel[LogItem]()): ServerLogger =
  ServerLogger(
    loggers: loggers,
    logFilter: logFilter,
    logQueue: logQueue,
  )

proc logLoop*(sl: ServerLogger) {.thread.} =
  sl.logQueue.open()

  for logger in sl.loggers:
    addHandler(logger)
  setLogFilter(sl.logFilter)

  var item: LogItem
  while true:
    item = sl.logQueue.recv()
    log(item.lvl, item.msg)

proc log*(sl: ServerLogger, msg: string, level: Level) =
  sl.logQueue.send(
    LogItem(msg: msg, lvl: level)
  )
