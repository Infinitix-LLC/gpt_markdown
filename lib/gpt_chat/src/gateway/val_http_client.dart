import 'package:http/http.dart' as http;

/// HTTP client for the render stream, on everything except the web.
///
/// The default client already delivers a response body incrementally, which is
/// what a newline-delimited render stream needs.
http.Client createValStreamClient() => http.Client();
