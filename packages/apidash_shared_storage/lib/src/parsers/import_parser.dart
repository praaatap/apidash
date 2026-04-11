import 'dart:convert';
import 'package:better_networking/better_networking.dart';
import 'package:curl_parser/curl_parser.dart' hide kHeaderContentType;
import 'package:har/har.dart' as har;
import 'package:insomnia_collection/insomnia_collection.dart' as ins;
import 'package:postman/postman.dart' as pm;

import '../models/imported_request.dart';
import '../utils/path_utils.dart';
import '../constants.dart';

List<ImportedRequest> parseImportedRequests(
  String content, {
  String format = 'auto',
}) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) return const [];

  final selected = format.toLowerCase() == 'auto'
      ? _detectImportFormat(trimmed)
      : format.toLowerCase();

  switch (selected) {
    case 'curl':
      return _parseCurlRequests(trimmed);
    case 'postman':
      return _parsePostmanRequests(trimmed);
    case 'insomnia':
      return _parseInsomniaRequests(trimmed);
    case 'har':
      return _parseHarRequests(trimmed);
    default:
      throw FormatException('Unsupported import format: $format');
  }
}

String _detectImportFormat(String content) {
  if (content.startsWith('curl ')) return 'curl';
  try {
    final decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('info') && decoded.containsKey('item')) {
        return 'postman';
      }
      if (decoded.containsKey('log')) return 'har';
      if (decoded.containsKey('resources')) return 'insomnia';
    }
  } catch (_) {}
  throw const FormatException(
    'Unable to detect import format. Use --format curl|postman|insomnia|har.',
  );
}

List<String> _splitCurlCommands(String content) {
  final commands = <String>[];
  final lines = content.split('\n');
  final buffer = StringBuffer();

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('curl ')) {
      if (buffer.isNotEmpty) {
        commands.add(buffer.toString().trim());
        buffer.clear();
      }
      buffer.writeln(line);
      continue;
    }
    if (buffer.isNotEmpty) {
      buffer.writeln(line);
    }
  }

  if (buffer.isNotEmpty) commands.add(buffer.toString().trim());
  if (commands.isEmpty && content.trim().startsWith('curl ')) {
    return [content.trim()];
  }
  return commands;
}

List<ImportedRequest> _parseCurlRequests(String content) {
  final commands = _splitCurlCommands(content);
  final out = <ImportedRequest>[];
  for (final command in commands) {
    final parsed = Curl.tryParse(command);
    if (parsed == null) continue;
    final req = _curlToRequest(parsed);
    out.add(
      ImportedRequest(
        name: '${req.method.abbr.toUpperCase()} ${req.url}',
        request: req,
      ),
    );
  }
  return out;
}

HttpRequestModel _curlToRequest(Curl curl) {
  final headersMap = <String, String>{...?(curl.headers)};
  String? body = curl.data;
  final formData = <FormDataModel>[];

  for (final entry in curl.formData ?? const <FormDataModel>[]) {
    formData.add(
      entry.type == FormDataType.file
          ? FormDataModel(name: entry.name, value: '', type: FormDataType.file)
          : entry,
    );
  }

  if ((curl.user?.isNotEmpty ?? false) &&
      !headersMap.keys.any((k) => k.toLowerCase() == 'authorization')) {
    final basic = base64.encode(utf8.encode(curl.user!));
    headersMap['Authorization'] = 'Basic $basic';
  }

  if ((curl.cookie?.isNotEmpty ?? false) &&
      !headersMap.keys.any((k) => k.toLowerCase() == 'cookie')) {
    headersMap['Cookie'] = curl.cookie!;
  }

  if ((curl.userAgent?.isNotEmpty ?? false) &&
      !headersMap.keys.any((k) => k.toLowerCase() == 'user-agent')) {
    headersMap['User-Agent'] = curl.userAgent!;
  }

  if ((curl.referer?.isNotEmpty ?? false) &&
      !headersMap.keys.any((k) => k.toLowerCase() == 'referer')) {
    headersMap['Referer'] = curl.referer!;
  }

  final contentType = curl.form
      ? ContentType.formdata
      : _contentTypeFromMime(headersMap['content-type']);

  if (contentType == ContentType.formdata && formData.isNotEmpty) {
    body = null;
  }

  return HttpRequestModel(
    method: HTTPVerb.values.byName(curl.method.toLowerCase()),
    url: _stripUrlParams(curl.uri.toString()),
    headers: _rowsFromStringMap(headersMap),
    params: _rowsFromStringMap(curl.uri.queryParameters),
    body: body,
    bodyContentType: contentType,
    formData: formData,
  );
}

List<ImportedRequest> _parsePostmanRequests(String content) {
  final collection = pm.postmanCollectionFromJsonStr(content);
  final requests = pm.getRequestsFromPostmanCollection(collection);
  return requests
      .map(
        (req) =>
            ImportedRequest(name: req.$1, request: _postmanToRequest(req.$2)),
      )
      .toList();
}

HttpRequestModel _postmanToRequest(pm.Request request) {
  HTTPVerb method;
  try {
    method = HTTPVerb.values.byName((request.method ?? '').toLowerCase());
  } catch (_) {
    method = kDefaultHttpMethod;
  }

  final headers = <NameValueModel>[];
  final isHeaderEnabledList = <bool>[];
  for (final header in request.header ?? const <pm.Header>[]) {
    headers.add(NameValueModel(name: header.key ?? '', value: header.value));
    isHeaderEnabledList.add(!(header.disabled ?? false));
  }

  final params = <NameValueModel>[];
  final isParamEnabledList = <bool>[];
  for (final query in request.url?.query ?? const <pm.Query>[]) {
    params.add(NameValueModel(name: query.key ?? '', value: query.value));
    isParamEnabledList.add(!(query.disabled ?? false));
  }

  var bodyContentType = kDefaultContentType;
  String? body;
  List<FormDataModel>? formData;

  if (request.body != null) {
    if (request.body?.mode == 'raw') {
      body = request.body?.raw;
      bodyContentType = _contentTypeFromLanguage(
        request.body?.options?.raw?.language,
      );
    } else if (request.body?.mode == 'formdata') {
      bodyContentType = ContentType.formdata;
      formData = <FormDataModel>[];
      for (final fd in request.body?.formdata ?? const <pm.Formdatum>[]) {
        final fdType = fd.type == 'file'
            ? FormDataType.file
            : FormDataType.text;
        final fdValue = fdType == FormDataType.file
            ? (fd.src ?? '')
            : (fd.value ?? '');
        formData.add(
          FormDataModel(name: fd.key ?? '', value: fdValue, type: fdType),
        );
      }
    }
  }

  return HttpRequestModel(
    method: method,
    url: _stripUrlParams(request.url?.raw ?? ''),
    headers: headers,
    params: params,
    isHeaderEnabledList: isHeaderEnabledList,
    isParamEnabledList: isParamEnabledList,
    body: body,
    bodyContentType: bodyContentType,
    formData: formData,
  );
}

List<ImportedRequest> _parseInsomniaRequests(String content) {
  final collection = ins.insomniaCollectionFromJsonStr(content);
  final requests = ins.getRequestsFromInsomniaCollection(collection);
  return requests
      .map(
        (req) =>
            ImportedRequest(name: req.$1, request: _insomniaToRequest(req.$2)),
      )
      .toList();
}

HttpRequestModel _insomniaToRequest(ins.Resource resource) {
  HTTPVerb method;
  try {
    method = HTTPVerb.values.byName((resource.method ?? '').toLowerCase());
  } catch (_) {
    method = kDefaultHttpMethod;
  }

  final headers = <NameValueModel>[];
  final isHeaderEnabledList = <bool>[];
  for (final header in resource.headers ?? const <ins.Header>[]) {
    headers.add(NameValueModel(name: header.name ?? '', value: header.value));
    isHeaderEnabledList.add(!(header.disabled ?? false));
  }

  final params = <NameValueModel>[];
  final isParamEnabledList = <bool>[];
  for (final param in resource.parameters ?? const <ins.Parameter>[]) {
    params.add(NameValueModel(name: param.name ?? '', value: param.value));
    isParamEnabledList.add(!(param.disabled ?? false));
  }

  final bodyContentType = _contentTypeFromMime(resource.body?.mimeType);
  String? body;
  List<FormDataModel>? formData;

  if (bodyContentType == ContentType.formdata) {
    formData = <FormDataModel>[];
    for (final fd in resource.body?.params ?? const <ins.Formdatum>[]) {
      final fdType = fd.type == 'file' ? FormDataType.file : FormDataType.text;
      final fdValue = fdType == FormDataType.file
          ? (fd.src ?? '')
          : (fd.value ?? '');
      formData.add(
        FormDataModel(name: fd.name ?? '', value: fdValue, type: fdType),
      );
    }
  } else {
    body = resource.body?.text;
  }

  return HttpRequestModel(
    method: method,
    url: _stripUrlParams(resource.url ?? ''),
    headers: headers,
    params: params,
    isHeaderEnabledList: isHeaderEnabledList,
    isParamEnabledList: isParamEnabledList,
    body: body,
    bodyContentType: bodyContentType,
    formData: formData,
  );
}

List<ImportedRequest> _parseHarRequests(String content) {
  final log = har.harLogFromJsonStr(content);
  final requests = har.getRequestsFromHarLog(log);
  return requests
      .map(
        (req) => ImportedRequest(name: req.$1, request: _harToRequest(req.$2)),
      )
      .toList();
}

HttpRequestModel _harToRequest(har.Request request) {
  HTTPVerb method;
  try {
    method = HTTPVerb.values.byName((request.method ?? '').toLowerCase());
  } catch (_) {
    method = kDefaultHttpMethod;
  }

  final headers = <NameValueModel>[];
  final isHeaderEnabledList = <bool>[];
  for (final header in request.headers ?? const <har.Header>[]) {
    headers.add(NameValueModel(name: header.name ?? '', value: header.value));
    isHeaderEnabledList.add(!(header.disabled ?? false));
  }

  final params = <NameValueModel>[];
  final isParamEnabledList = <bool>[];
  for (final query in request.queryString ?? const <har.Query>[]) {
    params.add(NameValueModel(name: query.name ?? '', value: query.value));
    isParamEnabledList.add(!(query.disabled ?? false));
  }

  var bodyContentType = _contentTypeFromMime(request.postData?.mimeType);
  String? body;
  List<FormDataModel>? formData;

  if (bodyContentType == ContentType.formdata) {
    formData = <FormDataModel>[];
    final postData = request.postData;
    if (postData?.mimeType == 'application/x-www-form-urlencoded') {
      for (final entry in _parseFormData(postData?.text).entries) {
        formData.add(
          FormDataModel(
            name: entry.key,
            value: entry.value,
            type: FormDataType.text,
          ),
        );
      }
    } else {
      for (final fd in postData?.params ?? const <har.Param>[]) {
        final isFile =
            (fd.contentType ?? '').isNotEmpty &&
            (fd.contentType ?? '') != 'text/plain';
        formData.add(
          FormDataModel(
            name: fd.name ?? '',
            value: isFile ? (fd.fileName ?? '') : (fd.value ?? ''),
            type: isFile ? FormDataType.file : FormDataType.text,
          ),
        );
      }
    }
  } else {
    body = request.postData?.text;
  }

  if (request.postData?.mimeType == 'application/json') {
    bodyContentType = ContentType.json;
  }

  return HttpRequestModel(
    method: method,
    url: _stripUrlParams(request.url ?? ''),
    headers: headers,
    params: params,
    isHeaderEnabledList: isHeaderEnabledList,
    isParamEnabledList: isParamEnabledList,
    body: body,
    bodyContentType: bodyContentType,
    formData: formData,
  );
}

Map<String, String> _parseFormData(String? data) {
  if (data == null || data.isEmpty) return {};
  final result = <String, String>{};
  for (final pair in data.split('&')) {
    final keyValue = pair.split('=');
    if (keyValue.length == 2) {
      result[Uri.decodeComponent(keyValue[0])] = Uri.decodeComponent(
        keyValue[1],
      );
    }
  }
  return result;
}

List<NameValueModel> _rowsFromStringMap(Map<String, String>? map) {
  if (map == null || map.isEmpty) return const [];
  return map.entries
      .map((e) => NameValueModel(name: e.key, value: e.value))
      .toList();
}

String _stripUrlParams(String rawUrl) {
  if (rawUrl.isEmpty) return rawUrl;
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) return rawUrl;
  return uri.replace(query: '', fragment: '').toString();
}

ContentType _contentTypeFromLanguage(String? language) {
  switch ((language ?? '').toLowerCase()) {
    case 'json':
      return ContentType.json;
    case 'text':
      return ContentType.text;
    default:
      return kDefaultContentType;
  }
}

ContentType _contentTypeFromMime(String? mimeType) {
  final mime = (mimeType ?? '').toLowerCase();
  if (mime.contains('json')) return ContentType.json;
  if (mime.contains('multipart/form-data') ||
      mime.contains('x-www-form-urlencoded')) {
    return ContentType.formdata;
  }
  if (mime.contains('text')) return ContentType.text;
  return kDefaultContentType;
}
