import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart' as http;

/// HTTP client for the render stream, on the web.
///
/// `package:http`'s browser client buffers the entire response before handing
/// any of it over, which would hold every frame back until the animation had
/// finished rendering. `FetchClient` exposes the Fetch streaming body, so
/// frames arrive as they are produced.
http.Client createValStreamClient() => FetchClient(mode: RequestMode.cors);
