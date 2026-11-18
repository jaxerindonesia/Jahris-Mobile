import 'dart:convert';
import 'dart:io';

const _upstreamOrigin = 'https://dev.jahris.id';
const _upstreamApi = '$_upstreamOrigin/api';
const _proxyPrefix = '/dev-api';
const _defaultPort = 3000;

final _httpClient = HttpClient()
  ..connectionTimeout = const Duration(seconds: 20);

Future<void> main(List<String> arguments) async {
  final port = arguments.isEmpty
      ? _defaultPort
      : int.tryParse(arguments.first) ?? _defaultPort;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln(
    'JAHRIS dev proxy aktif di http://${server.address.host}:$port$_proxyPrefix',
  );
  await for (final request in server) {
    await _handle(request);
  }
}

Future<void> _handle(HttpRequest request) async {
  final origin = request.headers.value('origin');
  if (!_isAllowedOrigin(origin)) {
    await _writeJson(request.response, HttpStatus.forbidden, {
      'message': 'Origin development tidak diizinkan.',
    });
    return;
  }

  _setCorsHeaders(request.response, origin);
  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  if (!request.uri.path.startsWith(_proxyPrefix)) {
    await _writeJson(request.response, HttpStatus.notFound, {
      'message': 'Gunakan path $_proxyPrefix.',
    });
    return;
  }

  final suffix = request.uri.path.substring(_proxyPrefix.length);
  final target = Uri.parse('$_upstreamApi${suffix.isEmpty ? '/' : suffix}')
      .replace(query: request.uri.hasQuery ? request.uri.query : null);

  try {
    final upstream = await _httpClient.openUrl(request.method, target);
    upstream.followRedirects = false;
    _copyRequestHeaders(request.headers, upstream.headers);
    await upstream.addStream(request);
    final response = await upstream.close();

    request.response.statusCode = response.statusCode;
    _copyResponseHeaders(response.headers, request.response.headers);
    _setCorsHeaders(request.response, origin);
    await request.response.addStream(response);
    await request.response.close();
  } on Object {
    await _writeJson(request.response, HttpStatus.badGateway, {
      'message': 'API JAHRIS tidak dapat dijangkau dari proxy lokal.',
    });
  }
}

bool _isAllowedOrigin(String? origin) {
  if (origin == null || origin.isEmpty) return true;
  final uri = Uri.tryParse(origin);
  return uri != null &&
      (uri.host == 'localhost' || uri.host == '127.0.0.1') &&
      (uri.scheme == 'http' || uri.scheme == 'https');
}

void _setCorsHeaders(HttpResponse response, String? origin) {
  if (origin != null && origin.isNotEmpty) {
    response.headers.set(HttpHeaders.accessControlAllowOriginHeader, origin);
    response.headers.set(
      HttpHeaders.accessControlAllowCredentialsHeader,
      'true',
    );
  }
  response.headers.set(
    HttpHeaders.accessControlAllowMethodsHeader,
    'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  );
  response.headers.set(
    HttpHeaders.accessControlAllowHeadersHeader,
    'Accept, Content-Type, Authorization, X-Requested-With',
  );
  response.headers.set(HttpHeaders.varyHeader, 'Origin');
}

void _copyRequestHeaders(HttpHeaders source, HttpHeaders target) {
  source.forEach((name, values) {
    if (_requestHeadersToReplace.contains(name.toLowerCase())) return;
    target.set(name, values);
  });
  target.set('origin', _upstreamOrigin);
  target.set(HttpHeaders.refererHeader, '$_upstreamOrigin/');
  target.set(HttpHeaders.hostHeader, Uri.parse(_upstreamOrigin).host);
}

void _copyResponseHeaders(HttpHeaders source, HttpHeaders target) {
  source.forEach((name, values) {
    if (_hopByHopHeaders.contains(name.toLowerCase())) return;
    target.set(name, values);
  });
}

Future<void> _writeJson(
  HttpResponse response,
  int statusCode,
  Map<String, dynamic> body,
) async {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}

const _requestHeadersToReplace = <String>{
  'host',
  'origin',
  'referer',
  'content-length',
  'connection',
};

const _hopByHopHeaders = <String>{
  'connection',
  'content-length',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
  'access-control-allow-origin',
  'access-control-allow-credentials',
  'access-control-allow-methods',
  'access-control-allow-headers',
  'vary',
};
