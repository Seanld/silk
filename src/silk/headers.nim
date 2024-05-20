import std/tables
import std/strutils
import std/times
import std/paths
import std/uri
import std/net

import ./status

type HeaderTable = TableRef[string, string]

type Response* = ref object
  protocol*: string
  status*: StatusCode
  headerFields*: HeaderTable
  content*: string

proc `$`*(h: Response): string {.gcsafe.} =
  var responseHeader = h.protocol & " " & $h.status.ord() & " " & STATUS_CODE_MAPPING[h.status.ord()] & "\r\n"

  for k, v in pairs(h.headerFields):
    responseHeader.add(k & ": " & v & "\r\n")

  if h.content != "":
    responseHeader.add("\r\n" & h.content)

  return responseHeader

proc newResponse*(status: StatusCode, headerTable: HeaderTable = nil, content: string = ""): Response =
  let time = now().utc.format("ddd, dd MMM yyyy hh:mm:ss 'GMT'")
  var headerFields: HeaderTable

  if headerTable == nil:
    headerFields = {
      "Server": "Silk",
      "Date": time,
    }.newTable
  else:
    headerFields = headerTable

  return Response(
    protocol: "HTTP/1.1",
    status: status,
    headerFields: headerFields,
    content: content,
  )

type Request* = ref object
  action*: string
  path*: Path
  uri*: Uri
  protocol*: string
  headerFields*: HeaderTable
  content*: string
  remoteAddr*: string

type EmptyRequestDefect* = object of Defect

proc parseReqHeader*(reqHeaderStr: string): Request =
  if reqHeaderStr == "":
    raise newException(EmptyRequestDefect, "Request from client was empty")

  var
    headerLines = reqHeaderStr.splitLines()
    headerFields = newTable[string, string]()
    methodLine = headerLines[0].split(" ")

  for line in headerLines[1..^2]:
    let splitted = line.split(": ")
    headerFields[splitted[0]] = splitted[1]

  let uri = parseUri(methodLine[1])

  var newHeader = Request(
    action: methodLine[0],
    uri: uri,
    path: Path(uri.path),
    protocol: methodLine[2],
    headerFields: headerFields,
  )

  # Normalize the path so to eliminate edge cases in path formatting.
  newHeader.path.normalizePath()

  return newHeader

proc recvReqHeaderStr*(client: Socket): string =
  var
    result = ""
    line = "" # Starting with empty string skips while loop.
  while true:
    line = client.recvLine(maxLength = 1024)
    if line == "\r\n" or line == "":
      break
    result.add(line & "\r\n")
  return result

# proc recvReqContentStr*(client: Socket, contentLength: int): Future[string] =
#   ## Receive content body as string into `header.content`.

type NotImplementedDefect = object of Defect

proc recvReq*(client: Socket, maxContentLen: int): Request =
  var req = parseReqHeader client.recvReqHeaderStr()

  # Add requestee's address.
  req.remoteAddr = client.getPeerAddr()[0]

  # Receive content body if one is attached.
  if req.headerFields.hasKey("Content-Length"):
    let contentLength = parseInt(req.headerFields["Content-Length"])
    req.content = client.recv(contentLength)

    if req.headerFields.hasKey("Transfer-Encoding"):
      let encoding = req.headerFields["Transfer-Encoding"]
      case encoding:
        of "chunked":
          raise newException(NotImplementedDefect, "HTTP/1.1 chunks are not yet implemented")
        of "compress":
          raise newException(NotImplementedDefect, "\"compress\" encoding will not be implemented")
        of "deflate":
          raise newException(NotImplementedDefect, "\"deflate\" compression not yet implemented")
        of "gzip":
          raise newException(NotImplementedDefect, "\"gzip\" compression not yet implemented")
        else:
          raise newException(Defect, "Invalid Transfer-Encoding type: " & encoding)

  return req
