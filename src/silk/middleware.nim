# This files implements a skeleton of a middleware, which
# actual middleware should "inherit" from.
#
# Due to circular dependency limitations with Nim, referring
# to the `Server` instance from a middleware is not currently
# possible. Will have to come up with some clean approach as
# a workaround.

import ./headers

type Middleware* = ref object of RootObj
  discard

proc newMiddleware*(): Middleware =
  ## For custom middleware, this will be what sets up values
  ## of the middleware object instance's attributes.
  Middleware()

proc useMiddleware*(): Middleware =
  ## Implemented by child middleware (useless in base middleware).
  ## Returns the middleware coerced to the `Middleware` type, which
  ## is useful when putting middleware in seq literals, for example.
  Middleware().Middleware

proc init*(m: Middleware) =
  ## Called by `Server` instance when it starts up. Can be useful
  ## for some middleware to handle setup tasks.
  discard

# type ProcessReqExitStatus = enum
#   discard

method processRequest*(m: Middleware, req: Request) {.base.} =
  ## Called by the `Server` instance when a request is inbound.
  ## Operations on the request (header+body) string can be done here.
  ## The result is passed on to the next middleware, or is handled
  ## by the `Server` if it's the last middleware in the pipeline.
  ## `ProcessStatus` indicates to the `Server` how to proceed after.
  discard

method processResponse*(m: Middleware, resp: Response) {.base.} =
  ## Called by the `Server` instance when a response is outbound.
  ## Operations on the response (header+body) string can be done here.
  ## The result is passed on to the next middleware, or is sent to
  ## the client if it is the last middleware in the pipeline.
  discard
