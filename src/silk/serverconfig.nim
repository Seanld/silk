# `ServerConfig` provides common options for configuring server settings
# (duh). It is used by `Server`, but is also referred to by other parts
# of the codebase, and due to Nim limitations with circular dependencies,
# this needs to be pulled out of `silk.nim`.

import std/tables
from std/math import `^`
from std/nativesockets import Port

type ServerConfig* = object
  host*: string
  port*: Port

  # How many clients to handle at one time, before new connections are dropped.
  maxClients*: int = 100
  # Limit content body size to a max size of 256 megabytes by default.
  maxContentLen*: int = 2^28

  customFields: Table[string, string]