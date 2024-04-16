import std/asyncnet
import std/asyncdispatch
import std/tables
import std/strutils
import std/times

import ./status

const REQ_HEADER_LINE_MAX_LEN = 1024

type HeaderTable = TableRef[string, string]

type ResponseHeader = object
  protocol*: string
  status*: StatusCode
  headerFields*: HeaderTable
  content*: string

proc `$`*(h: ResponseHeader): string =
  var responseHeader = h.protocol & " " & $h.status.ord() & " " & STATUS_CODE_MAPPING[h.status.ord()] & "\r\n"

  for k, v in pairs(h.headerFields):
    responseHeader.add(k & ": " & v & "\r\n")

  responseHeader.add("\r\n" & h.content)

  return responseHeader

proc newResponseHeader*(status: StatusCode, headerTable: HeaderTable = nil, content: string = ""): ResponseHeader =
  let time = now().utc.format("ddd, dd MMM yyyy hh:mm:ss 'GMT'")
  var headerFields: HeaderTable

  if headerTable == nil:
    headerFields = {
      "Server": "Silk",
      "Date": time,
    }.newTable
  else:
    headerFields = headerTable

  return ResponseHeader(
    protocol: "HTTP/1.1",
    status: status,
    headerFields: headerFields,
    content: content,
  )

type RequestHeader* = object
  action*: string
  path*: string
  protocol*: string
  headerFields*: HeaderTable
  content*: string

proc parseReqHeader*(reqHeaderStr: string): RequestHeader =
  var
    sections = reqHeaderStr.split("\r\n\r\n")
    headerLines = sections[0].splitLines()
    headerFields = newTable[string, string]()
    methodLine = headerLines[0].split(" ")

  var content = ""
  if sections.len > 1:
    content = sections[1]

  var newHeader = RequestHeader(
    action: methodLine[0],
    path: methodLine[1],
    protocol: methodLine[2],
    headerFields: headerFields,
    content: content,
  )

  for line in headerLines[1..^2]:
    let splitted = line.split(": ")
    headerFields[splitted[0]] = splitted[1]

  return newHeader

proc recvReqHeaderStr*(client: AsyncSocket): Future[string] {.async.} =
  var result = ""
  while true:
    let line = await client.recvLine(maxLength = REQ_HEADER_LINE_MAX_LEN)
    if line == "\r\n":
      break
    result.add(line & "\r\n")
  return result
