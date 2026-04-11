import 'package:better_networking/better_networking.dart';

class ImportedRequest {
  const ImportedRequest({required this.request, this.name});

  final HttpRequestModel request;
  final String? name;
}
