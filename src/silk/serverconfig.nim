# `ServerConfig` provides common options for configuring server settings
# (duh). It is used by `Server`, but is also referred to by other parts
# of the codebase, and due to Nim limitations with circular dependencies,
# this needs to be pulled out of `silk.nim`.

from std/math import `^`
from std/nativesockets import Port

import ./context
import ./status
import ./sugar
import ./serverlogger

handler defaultHandler:
  ctx.noContent(STATUS_NOT_FOUND)

type ServerConfig* = object
  host*: string
  port*: Port

  ## How many clients to handle at one time, before new connections are dropped.
  maxClients*: int = 100
  ## Limit content body size to a max size of 256 megabytes by default.
  maxContentLen*: int = 2^28

  ## When `true`, keep program alive, and log errors to loggers. If `false`,
  ## let the error kill the program.
  keepAlive* = true

  defaultHandler* = defaultHandler

  ## How many worker threads to create. Each worker can handle a
  ## connection at a time.
  workers* = 1

  serverLogger*: ServerLogger
