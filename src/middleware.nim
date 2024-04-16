# This files implements a skeleton of a middleware, which
# actual middleware should "inherit" from.
#
# Due to circular dependency limitations with Nim, referring
# to the `Server` instance from a middleware is not currently
# possible. Will have to come up with some clean approach as
# a workaround.

type Middleware = ref object
  discard

proc newMiddleware(): Middleware =
  ## For custom middleware, this will be what sets up values
  ## of the middleware object instance's attributes.
  discard

proc init(m: Middleware) =
  ## Called by `Server` instance when it starts up.
  discard

type ProcessStatus = enum
  NORMAL
  # Finish middleware pipeline, but skip normal routing. Useful
  # for sending a response before allowing default behaviour to
  # send a response instead.
  SKIP_REQ_ROUTING

proc processRequest(m: Middleware, req: string): tuple[req: string, status: ProcessStatus] =
  ## Called by the `Server` instance when a request is inbound.
  ## Operations on the request (header+body) string can be done here.
  ## The result is passed on to the next middleware, or is handled
  ## by the `Server` if it's the last middleware in the pipeline.
  ## `ProcessStatus` indicates to the `Server` how to proceed after.
  return (req: "", status: NORMAL)

proc processResponse(m: Middleware, resp: string): string =
  ## Called by the `Server` instance when a response is outbound.
  ## Operations on the response (header+body) string can be done here.
  ## The result is passed on to the next middleware, or is sent to
  ## the client if it is the last middleware in the pipeline.
  return ""
