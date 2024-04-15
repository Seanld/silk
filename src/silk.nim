import std/asyncnet
import std/asyncdispatch
import std/tables
import std/strutils

const
  REQ_HEADER_LINE_MAX_LEN = 1024
  REQ_CHUNK_SIZE = 10

let STATUS_CODE_MAPPING = {
  200'u16: "OK",
  400'u16: "Bad Request",
}.toTable

type HeaderField = tuple[key: string, val: string]

proc newResponseHeader(code: uint16, headerFields: varargs[HeaderField]): string =
  var responseHeader = ""

  responseHeader.add($code & " " & STATUS_CODE_MAPPING[code] & "\r\n")

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

  for line in headerLines[1..^1]:
    let splitted = line.split(": ")
    fieldsTable[splitted[0]] = splitted[1]

  return newHeader

proc recvReqHeader(client: AsyncSocket): Future[string] {.async.} =
  var result = ""
  while true:
    let line = await client.recvLine(maxLength = REQ_HEADER_LINE_MAX_LEN)
    if line == "\r\n":
      break
    result.add(result)
  return result

proc handleClient(client: AsyncSocket) {.async.} =
  var
    reqHeader = (await client.recvReqHeader()).parseReqHeader()
    resp = ""

  echo repr(reqHeader)

  # if reqHeader.path == "/test":
  #   resp = newResponseHeader(200, ("Server", "Silk"), ("Test", "Hello, world!"))
  # else:
  #   resp = newResponseHeader(400, ("Server", "Silk"), ("Msg", "Ruh roh raggy!"))

  # await client.send(resp)
  # client.close()

type Server* = object
  host*: string
  port*: Port
  maxClients*: uint64

proc serve(s: Server) {.async.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(s.port, s.host)
  server.listen()

  while true:
    let client = await server.accept()
    asyncCheck handleClient(client)

proc start*(s: Server) =
  asyncCheck serve()
  runForever()
