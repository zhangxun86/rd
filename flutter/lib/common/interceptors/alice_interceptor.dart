import 'package:alice/alice.dart';
import 'package:alice/model/alice_http_call.dart';
import 'package:alice/model/alice_http_request.dart';
import 'package:alice/model/alice_http_response.dart';
import 'package:dio/dio.dart';

/// A custom Dio interceptor that bridges Dio's request/response cycle
/// with the Alice network inspector.
///
/// This interceptor manually creates and logs `AliceHttpCall` objects
/// for both successful responses and errors.
class AliceDioInterceptor extends Interceptor {
  final Alice alice;

  AliceDioInterceptor(this.alice);

  /// Called when a response is received.
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logCall(response: response);
    super.onResponse(response, handler);
  }

  /// Called when an error occurs.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Also log the call on error, as it might contain useful response data.
    _logCall(response: err.response);
    super.onError(err, handler);
  }

  /// Helper method to construct and log an `AliceHttpCall`.
  void _logCall({Response? response}) {
    if (response == null) {
      // We can't log a call without a response that contains the request options.
      return;
    }

    final RequestOptions request = response.requestOptions;

    // Create the Alice call object, identified by the request's hash code.
    final AliceHttpCall call = AliceHttpCall(request.hashCode)
      ..method = request.method
      ..uri = request.uri.toString()
      ..endpoint = request.path;

    // --- Manually populate the Request object for Alice ---
    final AliceHttpRequest aliceRequest = AliceHttpRequest();

    aliceRequest.time = DateTime.now(); // Approximate time
    aliceRequest.headers = request.headers.map((key, value) => MapEntry(key, value.toString()));
    aliceRequest.contentType = request.contentType;
    aliceRequest.body = request.data;
    aliceRequest.queryParameters = request.queryParameters;

    // --- Manually populate the Response object for Alice ---
    final AliceHttpResponse aliceResponse = AliceHttpResponse();

    aliceResponse.time = DateTime.now();
    aliceResponse.status = response.statusCode;
    // Convert Dio's `Headers` object to a simple Map.
    aliceResponse.headers = response.headers.map.map((key, value) => MapEntry(key, value.join(', ')));
    aliceResponse.body = response.data;

    // Calculate size for logging purposes.
    if (response.data != null) {
      aliceResponse.size = response.data.toString().length;
    }

    // Assign the manually populated objects to the call.
    call.request = aliceRequest;
    call.response = aliceResponse;
    call.loading = false;

    // Finally, add the completed call to Alice.
    alice.addHttpCall(call);
  }
}