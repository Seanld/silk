const statusCodeMapping = {
  100: "Continue",
  101: "Switching Protocols",
  102: "Processing",
  103: "Early Hints",

  200: "OK",
  201: "Created",
  202: "Accepted",
  203: "Non-Authoritative Information",
  204: "No Content",
  205: "Reset Content",
  206: "Partial Content",
  207: "Multi-Status",
  208: "Already Reported",
  226: "IM Used",

  300: "Multiple Choices",
  301: "Moved Permanently",
  302: "Found",
  303: "See Other",
  304: "Not Modified",
  305: "Use Proxy", # Deprecated
  307: "Temporary Redirect",
  308: "Permanent Redirect",

  400: "Bad Request",
  401: "Unauthorized",
  402: "Payment Required",
  403: "Forbidden",
  404: "Not Found",
  405: "Method Not Allowed",
  406: "Not Acceptable",
  407: "Proxy Authentication Required",
  408: "Request Timeout",
  409: "Conflict",
  410: "Gone",
  411: "Length Required",
  412: "Precondition Failed",
  413: "Payload Too Large",
  414: "URI Too Long",
  415: "Unsupported Media Type",
  416: "Range Not Satisfiable",
  417: "Expectation Failed",
  418: "I'm a teapot",
  421: "Misdirected Request",
  422: "Unprocessable Content",
  423: "Locked",
  424: "Failed Dependency",
  425: "Too Early",
  426: "Upgrade Required",
  428: "Precondition Required",
  429: "Too Many Requests",
  431: "Request Header Fields Too Large",
  451: "Unavailable For Legal Reasons",

  500: "Internal Server Error",
  501: "Not Implemented",
  502: "Bad Gateway",
  503: "Service Unavailable",
  504: "Gateway Timeout",
  505: "HTTP Version Not Supported",
  506: "Variant Also Negotiates",
  507: "Insufficient Storage",
  508: "Loop Detected",
  510: "Not Extended",
  511: "Network Authentication Required",
}

type StatusCode = enum
  STATUS_CONTINUE = 100
  STATUS_SWITCHING_PROTOCOLS = 101
  STATUS_PROCESSING = 102
  STATUS_EARLY_HINTS = 103

  STATUS_OK = 200
  STATUS_CREATED = 201
  STATUS_ACCEPTED = 202
  STATUS_NON_AUTHORITATIVE_INFORMATION = 203
  STATUS_NO_CONTENT = 204
  STATUS_RESET_CONTENT = 205
  STATUS_PARTIAL_CONTENT = 206
  STATUS_MULTI_STATUS = 207
  STATUS_ALREADY_REPORTED = 208
  STATUS_IM_USED = 226

  STATUS_MULTIPLE_CHOICES = 300
  STATUS_MOVED_PERMANENTLY = 301
  STATUS_FOUND = 302
  STATUS_SEE_OTHER = 303
  STATUS_NOT_MODIFIED = 304
  STATUS_USE_PROXY = 305
  STATUS_TEMPORARY_REDIRECT = 307
  STATUS_PERMANENT_REDIRECT = 308

  STATUS_BAD_REQUEST = 400
  STATUS_UNAUTHORIZED = 401
  STATUS_PAYMENT_REQUIRED = 402
  STATUS_FORBIDDEN = 403
  STATUS_NOT_FOUND = 404
  STATUS_METHOD_NOT_ALLOWED = 405
  STATUS_NOT_ACCEPTABLE = 406
  STATUS_PROXY_AUTHENTICATION_REQUIRED = 407
  STATUS_REQUEST_TIMEOUT = 408
  STATUS_CONFLICT = 409
  STATUS_GONE = 410
  STATUS_LENGTH_REQUIRED = 411
  STATUS_PRECONDITION_FAILED = 412
  STATUS_PAYLOAD_TOO_LARGE = 413
  STATUS_URI_TOO_LONG = 414
  STATUS_UNSUPPORTED_MEDIA_TYPE = 415
  STATUS_RANGE_NOT_SATISFIABLE = 416
  STATUS_EXPECTATION_FAILED = 417
  STATUS_IM_A_TEAPOT = 418
  STATUS_MISDIRECTED_REQUEST = 421
  STATUS_UNPROCESSABLE_CONTENT = 422
  STATUS_LOCKED = 423
  STATUS_FAILED_DEPENDENCY = 424
  STATUS_TOO_EARLY = 425
  STATUS_UPGRADE_REQUIRED = 426
  STATUS_PRECONDITION_REQUIRED = 428
  STATUS_TOO_MANY_REQUESTS = 429
  STATUS_REQUEST_HEADER_FIELDS_TOO_LARGE = 431
  STATUS_UNAVAILABLE_FOR_LEGAL_REASONS = 451

  STATUS_INTERNAL_SERVER_ERROR = 500
  STATUS_NOT_IMPLEMENTED = 501
  STATUS_BAD_GATEWAY = 502
  STATUS_SERVICE_UNAVAILABLE = 503
  STATUS_GATEWAY_TIMEOUT = 504
  STATUS_HTTP_VERSION_NOT_SUPPORTED = 505
  STATUS_VARIANT_ALSO_NEGOTIATES = 506
  STATUS_INSUFFICIENT_STORAGE = 507
  STATUS_LOOP_DETECTED = 508
  STATUS_NOT_EXTENDED = 510
  STATUS_NETWORK_AUTHENTICATION_REQUIRED = 511
