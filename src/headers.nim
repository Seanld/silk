const
  REQ_HEADER_LINE_MAX_LEN = 1024

type HeaderField = tuple[key: string, val: string]

proc newResponseHeader(code: uint16, headerFields: varargs[HeaderField]): string =
  var responseHeader = ""

  responseHeader.add("HTTP/1.1 " & $code & " " & STATUS_CODE_MAPPING[code] & "\r\n")

  for f in headerFields:
    responseHeader.add(f.key & ": " & f.val & "\r\n")

  return responseHeader

type RequestHeader* = object
  action*: string
  path*: string
  protocol*: string
  fields*: ref Table[string, string]

proc parseReqHeader(reqHeaderStr: string): RequestHeader =
  var
    headerLines = reqHeaderStr.splitLines()
    fieldsTable = newTable[string, string]()
    methodLine = headerLines[0].split(" ")

  var newHeader = RequestHeader(
    action: methodLine[0],
    path: methodLine[1],
    protocol: methodLine[2],
    fields: fieldsTable,
  )

  for line in headerLines[1..^2]:
    let splitted = line.split(": ")
    fieldsTable[splitted[0]] = splitted[1]

  return newHeader

proc recvReqHeader(client: AsyncSocket): Future[string] {.async.} =
  var result = ""
  while true:
    let line = await client.recvLine(maxLength = REQ_HEADER_LINE_MAX_LEN)
    if line == "\r\n":
      break
    result.add(line & "\r\n")
  return result