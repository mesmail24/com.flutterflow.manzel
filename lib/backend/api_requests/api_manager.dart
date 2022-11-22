import 'dart:convert';
import 'dart:io';
import 'dart:core';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import 'package:manzel/app_state.dart';
import 'package:manzel/auth/auth_util.dart';

enum ApiCallType {
  GET,
  POST,
  DELETE,
  PUT,
  PATCH,
}

enum BodyType {
  NONE,
  JSON,
  TEXT,
  X_WWW_FORM_URL_ENCODED,
}

class ApiCallRecord extends Equatable {
  ApiCallRecord(this.callName, this.apiUrl, this.headers, this.params,
      this.body, this.bodyType);
  final String callName;
  final String apiUrl;
  final Map<String, dynamic> headers;
  final Map<String, dynamic> params;
  final String? body;
  final BodyType? bodyType;


  @override
  List<Object?> get props =>
      [callName, apiUrl, headers, params, body, bodyType];
}

class ApiCallResponse {
  const ApiCallResponse(this.jsonBody, this.headers, this.statusCode);
  final dynamic jsonBody;
  final Map<String, String> headers;
  final int statusCode;

  // Whether we received a 2xx status (which generally marks success).
  bool get succeeded => statusCode >= 200 && statusCode < 300;
  String getHeader(String headerName) => headers[headerName] ?? '';

  static ApiCallResponse fromHttpResponse(
    http.Response response,
    bool returnBody,
  ) {
    var jsonBody;
    try {
      jsonBody = returnBody ? json.decode(response.body) : null;
    } catch (_) {}
    return ApiCallResponse(jsonBody, response.headers, response.statusCode);
  }

  static ApiCallResponse fromCloudCallResponse(Map<String, dynamic> response) =>
      ApiCallResponse(
        response['body'],
        ApiManager.toStringMap(response['headers'] ?? {}),
        response['statusCode'] ?? 400,
      );
}

class ApiManager {
  ApiManager._();

  // Cache that will ensure identical calls are not repeatedly made.
  static Map<ApiCallRecord, ApiCallResponse> _apiCache = {};

  static ApiManager? _instance;
  static ApiManager get instance => _instance ??= ApiManager._();

  // If your API calls need authentication, populate this field once
  // the user has authenticated. Alter this as needed.
  static String? _accessToken;

  // You may want to call this if, for example, you make a change to the
  // database and no longer want the cached result of a call that may
  // have changed.
  static void clearCache(String callName) => _apiCache.keys
      .toSet()
      .forEach((k) => k.callName == callName ? _apiCache.remove(k) : null);

  static Map<String, String> toStringMap(Map map) =>
      map.map((key, value) => MapEntry(key.toString(), value.toString()));

  static String asQueryParams(Map<String, dynamic> map) =>
      map.entries.map((e) => "${e.key}=${e.value}").join('&');

  static Future<ApiCallResponse> urlRequest(
    ApiCallType callType,
    String apiUrl,
    Map<String, dynamic> headers,
    Map<String, dynamic> params,
    bool returnBody,
  ) async {
    if (params.isNotEmpty) {
      final lastUriPart = apiUrl.split('/').last;
      final needsParamSpecifier = !lastUriPart.contains('?');
      apiUrl =
          '$apiUrl${needsParamSpecifier ? '?' : ''}${asQueryParams(params)}';
    }
    final makeRequest = callType == ApiCallType.GET ? http.get : http.delete;
    final response =
        await makeRequest(Uri.parse(apiUrl), headers: toStringMap(headers));
    if(response.statusCode != null &&response.statusCode==401){
      final updatedHeader = await refreshToken(headers);
      final updatedResponse = await makeRequest(Uri.parse(apiUrl), headers: toStringMap(updatedHeader));
      if(updatedResponse.statusCode!=null && updatedResponse.statusCode==401){signOut();}
      return ApiCallResponse.fromHttpResponse(updatedResponse, returnBody);
    }
    return ApiCallResponse.fromHttpResponse(response, returnBody);
  }

  static Future<ApiCallResponse> requestWithBody(
    ApiCallType type,
    String apiUrl,
    Map<String, dynamic> headers,
    Map<String, dynamic> params,
    String? body,
    BodyType? bodyType,
    bool returnBody,

  ) async {
    assert(
      {ApiCallType.POST, ApiCallType.PUT, ApiCallType.PATCH}.contains(type),
      'Invalid ApiCallType $type for request with body',
    );
    final postBody = createBody(headers, params, body, bodyType);
    final requestFn = {
      ApiCallType.POST: http.post,
      ApiCallType.PUT: http.put,
      ApiCallType.PATCH: http.patch,
    }[type]!;

    final response = await requestFn(Uri.parse(apiUrl),
        headers: toStringMap(headers), body: postBody,);
    if(response.statusCode != null &&response.statusCode==401){
      final updatedHeader = await refreshToken(headers);
      final updatedResponse = await requestFn(Uri.parse(apiUrl),
          headers: toStringMap(updatedHeader), body: postBody);
      if(updatedResponse.statusCode != null &&updatedResponse.statusCode==401){signOut();}
      return ApiCallResponse.fromHttpResponse(updatedResponse, returnBody);
    }
    return ApiCallResponse.fromHttpResponse(response, returnBody);
  }

  static dynamic createBody(
    Map<String, dynamic> headers,
    Map<String, dynamic>? params,
    String? body,
    BodyType? bodyType,
  ) {
    String? contentType;
    dynamic postBody;
    switch (bodyType) {
      case BodyType.JSON:
        contentType = 'application/json';
        postBody = body ?? json.encode(params ?? {});
        break;
      case BodyType.TEXT:
        contentType = 'text/plain';
        postBody = body ?? json.encode(params ?? {});
        break;
      case BodyType.X_WWW_FORM_URL_ENCODED:
        contentType = 'application/x-www-form-urlencoded';
        postBody = toStringMap(params ?? {});
        break;
      case BodyType.NONE:
      case null:
        break;
    }
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }
    return postBody;
  }

  Future<ApiCallResponse> makeApiCall({
    required String callName,
    required String apiUrl,
    required ApiCallType callType,
    Map<String, dynamic> headers = const {},
    Map<String, dynamic> params = const {},
    String? body,
    BodyType? bodyType,
    bool returnBody = true,
    bool cache = false,
  }) async {
    final callRecord =
        ApiCallRecord(callName, apiUrl, headers, params, body, bodyType);
    // Modify for your specific needs if this differs from your API.
    if (_accessToken != null) {
      headers[HttpHeaders.authorizationHeader] = 'Token $_accessToken';
    }
    if (!apiUrl.startsWith('http')) {
      apiUrl = 'https://$apiUrl';
    }

    // If we've already made this exact call before and caching is on,
    // return the cached result.
    if (cache && _apiCache.containsKey(callRecord)) {
      return _apiCache[callRecord]!;
    }

    ApiCallResponse result;
    switch (callType) {
      case ApiCallType.GET:
      case ApiCallType.DELETE:
        result =
            await urlRequest(callType, apiUrl, headers, params, returnBody);
        break;
      case ApiCallType.POST:
      case ApiCallType.PUT:
      case ApiCallType.PATCH:
        result = await requestWithBody(
            callType, apiUrl, headers, params, body, bodyType, returnBody);
        break;
    }

    // If caching is on, cache the result (if present).
    if (cache) {
      _apiCache[callRecord] = result;
    }

    return result;
  }


  Future<ApiCallResponse> generateOtpApiCall({
    required String callName,
    required String apiUrl,
    required ApiCallType callType,
    Map<String, dynamic> headers = const {},
    Map<String, dynamic> params = const {},
    String? body,
    BodyType? bodyType,
    bool returnBody = true,
    bool cache = false,

  }) async {
    final callRecord =
    ApiCallRecord(callName, apiUrl, headers, params, body, bodyType);
    // Modify for your specific needs if this differs from your API.
    // if (_accessToken != null) {
    //   headers[HttpHeaders.authorizationHeader] = 'Token $_accessToken';
    // }
    if (!apiUrl.startsWith('http')) {
      apiUrl = 'https://$apiUrl';
    }

    // If we've already made this exact call before and caching is on,
    // return the cached result.
    if (cache && _apiCache.containsKey(callRecord)) {
      return _apiCache[callRecord]!;
    }

    ApiCallResponse result;
    switch (callType) {
      case ApiCallType.GET:
      case ApiCallType.DELETE:
        result =
        await urlRequest(callType, apiUrl, headers, params, returnBody);
        break;
      case ApiCallType.POST:
      case ApiCallType.PUT:
      case ApiCallType.PATCH:
        result = await requestWithBody(
            callType, apiUrl, headers, params, body, bodyType, returnBody);
        break;
    }

    // If caching is on, cache the result (if present).
    if (cache) {
      _apiCache[callRecord] = result;
    }

    return result;
  }
}

Future<Map<String,dynamic>> refreshToken(Map<String,dynamic> header) async {
  if (FirebaseAuth.instance.currentUser != null) {
  final user = FirebaseAuth.instance.currentUser;
  final idTokenResult = await user!.getIdTokenResult(true);
  final token = idTokenResult.token;
  FFAppState().authToken ='';
  FFAppState().authToken = token!;
  }
  header['Authorization'] = "Bearer "+FFAppState().authToken;
  return header;
}