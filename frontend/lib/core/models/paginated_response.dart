class PaginatedResponse<T> {
  final List<T> items;
  final String? lastDocId;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    required this.lastDocId,
    required this.hasMore,
  });
}

