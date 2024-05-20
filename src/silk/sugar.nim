import ./context

template handler*(code: untyped): untyped =
  proc(ctx{.inject.}: Context) = code

template handler*(name: untyped, code: untyped): untyped =
  proc name(ctx{.inject.}: Context) = code
