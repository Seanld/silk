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
  100_CONTINUE
  101_SWITCHING_PROTOCOLS
  102_PROCESSING
  103_EARLY_HINTS

  200_OK
  201_CREATED
  202_ACCEPTED
  203_NON_AUTHORITATIVE_INFORMATION
  204_NO_CONTENT
  205_RESET_CONTENT
  206_PARTIAL_CONTENT
  207_MULTI_STATUS
  208_ALREADY_REPORTED
  226_IM_USED

  300_MULTIPLE_CHOICES
  301_MOVED_PERMANENTLY
  302_FOUND
  303_SEE_OTHER
  304_NOT_MODIFIED
  305_USE_PROXY
  307_TEMPORARY_REDIRECT
  308_PERMANENT_REDIRECT

  400_BAD_REQUEST
  401_UNAUTHORIZED
  402_PAYMENT_REQUIRED
  403_FORBIDDEN
  404_NOT_FOUND
  405_METHOD_NOT_ALLOWED
  406_NOT_ACCEPTABLE
  407_PROXY_AUTHENTICATION_REQUIRED
  408_REQUEST_TIMEOUT
  409_CONFLICT
  410_GONE
  411_LENGTH_REQUIRED
  412_PRECONDITION_FAILED
  413_PAYLOAD_TOO_LARGE
  414_URI_TOO_LONG
  415_UNSUPPORTED_MEDIA_TYPE
  416_RANGE_NOT_SATISFIABLE
  417_EXPECTATION_FAILED
  418_I'M_A_TEAPOT
  421_MISDIRECTED_REQUEST
  422_UNPROCESSABLE_CONTENT
  423_LOCKED
  424_FAILED_DEPENDENCY
  425_TOO_EARLY
  426_UPGRADE_REQUIRED
  428_PRECONDITION_REQUIRED
  429_TOO_MANY_REQUESTS
  431_REQUEST_HEADER_FIELDS_TOO_LARGE
  451_UNAVAILABLE_FOR_LEGAL_REASONS

  500_INTERNAL_SERVER_ERROR
  501_NOT_IMPLEMENTED
  502_BAD_GATEWAY
  503_SERVICE_UNAVAILABLE
  504_GATEWAY_TIMEOUT
  505_HTTP_VERSION_NOT_SUPPORTED
  506_VARIANT_ALSO_NEGOTIATES
  507_INSUFFICIENT_STORAGE
  508_LOOP_DETECTED
  510_NOT_EXTENDED
  511_NETWORK_AUTHENTICATION_REQUIRED
