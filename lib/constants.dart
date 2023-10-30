// const apiUrl = 'http://localhost:3000/api';
const apiUrl = 'http://192.168.86.33:3000/api';

class JSONResponse<T> {
  final T data;
  final List<Error> errors;

  JSONResponse({required this.data, required this.errors});
}

class PaginationMetadata {
  final int total;
  final int currentOffset;
  final int currentLimit;
  final PaginationPointer? prev;
  final PaginationPointer? next;

  PaginationMetadata({
    required this.total,
    required this.currentOffset,
    required this.currentLimit,
    this.prev,
    this.next,
  });
  PaginationMetadata.fromJson(Map<String, dynamic> json)
      : total = json['total'],
        currentOffset = json['currentOffset'],
        currentLimit = json['currentLimit'],
        prev = json['prev'] != null
            ? PaginationPointer.fromJson(json['prev'])
            : null,
        next = json['next'] != null
            ? PaginationPointer.fromJson(json['next'])
            : null;
}

class PaginationPointer {
  final int offset;
  final int limit;

  PaginationPointer({
    required this.offset,
    required this.limit,
  });
  PaginationPointer.fromJson(Map<String, dynamic> json)
      : offset = json['offset'],
        limit = json['limit'];
}

class Sort {
  final String? key;
  final String? order;

  Sort({this.key, this.order});
}
