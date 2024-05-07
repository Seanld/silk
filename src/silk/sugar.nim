import std/asyncdispatch

import ./context

export asyncdispatch

template handler*(code: untyped): untyped =
  proc(ctx{.inject.}: Context) {.async.} = code

template handler*(name: untyped, code: untyped): untyped =
  proc name(ctx{.inject.}: Context) {.async.} = code
