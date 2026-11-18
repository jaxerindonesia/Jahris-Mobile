class ApiPageMeta {
  const ApiPageMeta({
    required this.page,
    required this.total,
    required this.hasMore,
  });

  final int page;
  final int total;
  final bool hasMore;
}

List<Map<String, dynamic>> apiList(
  dynamic body, {
  List<String> collectionKeys = const [],
}) {
  dynamic candidate = body;
  if (candidate is Map<String, dynamic>) {
    candidate = candidate['data'] ?? candidate;
  }
  if (candidate is Map<String, dynamic>) {
    for (final key in ['items', ...collectionKeys]) {
      final value = candidate[key];
      if (value is List) {
        candidate = value;
        break;
      }
    }
  }
  if (candidate is! List) return const [];
  return candidate.whereType<Map<String, dynamic>>().toList();
}

Map<String, dynamic> apiObject(dynamic body) {
  if (body is! Map<String, dynamic>) return const {};
  final data = body['data'];
  return data is Map<String, dynamic> ? data : body;
}

ApiPageMeta apiPageMeta(
  dynamic body, {
  required int fallbackPage,
  required int itemCount,
  required int limit,
}) {
  Map<String, dynamic> root = const {};
  if (body is Map<String, dynamic>) root = body;
  final data = root['data'];
  final metaCandidate =
      root['meta'] ??
      root['pagination'] ??
      (data is Map<String, dynamic>
          ? data['meta'] ?? data['pagination']
          : null);
  final meta = metaCandidate is Map<String, dynamic>
      ? metaCandidate
      : const <String, dynamic>{};
  final page = _integer(meta['page'] ?? meta['currentPage']) ?? fallbackPage;
  final total =
      _integer(meta['total'] ?? meta['totalItems'] ?? root['total']) ??
      itemCount;
  final totalPages = _integer(meta['totalPages'] ?? meta['pages']);
  final explicitHasMore = meta['hasMore'];
  final hasMore = explicitHasMore is bool
      ? explicitHasMore
      : totalPages != null
      ? page < totalPages
      : page * limit < total;
  return ApiPageMeta(page: page, total: total, hasMore: hasMore);
}

int? _integer(dynamic value) {
  if (value is num) return value.toInt();
  return value is String ? int.tryParse(value) : null;
}
