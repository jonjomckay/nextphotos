import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:nextcloud/nextcloud.dart';
import 'package:xml/xml.dart';

class CustomClient {
  CustomClient(
    this._baseUrl,
    this._username,
    String password,
  ) {
    final client = NextCloudHttpClient(_username, password);
    _network = Network(client);
  }

  final String _baseUrl;
  final String _username;

  late Network _network;

  // Copied from the nextcloud package
  final Map<String, String> namespaces = {
    'DAV:': 'd',
    'http://owncloud.org/ns': 'oc',
    'http://nextcloud.org/ns': 'nc',
    'https://github.com/icewind1991/SearchDAV/ns': 'ns',
    'http://open-collaboration-services.org/ns': 'ocs',
  };

  Future<List<WebDavFile>> search(
    String remotePath,
    int limit,
    int offset,
    List<MapEntry<String, String>> propFilters, {
    Set<String> props = const {},
  }) async {
    final builder = XmlBuilder();

    builder
      ..processing('xml', 'version="1.0" encoding="UTF-8"')
      ..element('d:searchrequest', nest: () {
        namespaces.forEach(builder.namespace);

        builder
          ..element('d:basicsearch', nest: () {
            builder
              ..element('d:select', nest: () {
                builder
                  ..element('d:prop', nest: () {
                    props.forEach(builder.element);
                  });
              })
              ..element('d:from', nest: () {
                builder
                  ..element('d:scope', nest: () {
                    builder.element('d:href', nest: () {
                      builder.text(remotePath);
                    });

                    builder.element('d:depth', nest: () {
                      builder.text('infinity');
                    });
                  });
              })
              ..element('d:where', nest: () {
                builder.element('d:and', nest: () {
                  builder
                    ..element('d:or', nest: () {
                      propFilters.forEach((entry) {
                        builder.element('d:eq', nest: () {
                          builder
                            ..element('d:prop', nest: () {
                              builder.element(entry.key);
                            })
                            ..element('d:literal', nest: () {
                              // TODO
                              builder.text(entry.value);
                            });
                        });
                      });
                    })
                    ..element('d:eq', nest: () {
                      builder
                        ..element('d:prop', nest: () {
                          builder.element('oc:owner-id');
                        })
                        ..element('d:literal', nest: () {
                          builder.text(_username);
                        });
                    });
                });
              })
              ..element('d:orderby', nest: () {
                builder.element('d:order', nest: () {
                  builder
                    ..element('d:prop', nest: () {
                      builder.element('d:getlastmodified');
                    })
                    ..element('d:descending');
                });
              })
              ..element('d:limit', nest: () {
                builder
                  ..element('d:nresults', nest: () {
                    builder.text(limit.toString());
                  })
                  ..element('ns:firstresult', nest: () {
                    builder.text(offset.toString());
                  });
              });
          });
      });

    var doc = builder.buildDocument().toString();

    final data = utf8.encode(doc);

    final response = await _network.send(
      'SEARCH',
      '$_baseUrl/remote.php/dav',
      [200, 207],
      data: data,
    );

    return treeFromWebDavXml(response.body);
  }
}

// ignore: public_member_api_docs
class HttpClient extends http.BaseClient {
  // ignore: public_member_api_docs
  HttpClient() : _client = http.Client() as http.BaseClient;

  final http.BaseClient _client;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _client.send(request);
}

/// Http client with the correct authentication and header
class NextCloudHttpClient extends HttpClient {
  /// Creates a client wrapping [inner] that uses Basic HTTP auth.
  ///
  /// Constructs a new [NextCloudHttpClient] which will use the provided [username]
  /// and [password] for all subsequent requests.
  NextCloudHttpClient(
    this.username,
    this.password, {
    inner,
    this.useJson = false,
  })  : _authString = 'Basic ${base64.encode(utf8.encode('$username:$password')).trim()}',
        _inner = inner ?? HttpClient();

  /// The username to be used for all requests
  final String username;

  /// The password to be used for all requests
  final String password;

  // ignore: public_member_api_docs
  final bool useJson;

  final http.Client _inner;
  final String _authString;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['Authorization'] = _authString;
    request.headers['OCS-APIRequest'] = 'true';

    final format = useJson ? 'json' : 'xml';
    request.headers['Content-Type'] = 'application/$format';
    request.headers['Accept'] = 'application/$format';

    return _inner.send(request);
  }
}

/// RequestException class
class RequestException implements Exception {
  // ignore: public_member_api_docs
  RequestException(this.cause, this.statusCode);

  // ignore: public_member_api_docs
  String cause;

  // ignore: public_member_api_docs
  int statusCode;
}

/// Organizes the requests
class Network {
  /// Create a network with the given client and base url
  Network(this.client);

  /// The http client
  final http.Client client;

  /// send the request with given [method] and [url]
  Future<http.Response> send(
    String method,
    String url,
    List<int> expectedCodes, {
    List<int>? data,
    Map<String, String>? headers,
  }) async {
    final response = await client.send(http.Request(method, Uri.parse(url))
      ..followRedirects = false
      ..persistentConnection = true
      ..bodyBytes = data ?? Uint8List(0)
      ..headers.addAll(headers ?? {}));
    if (!expectedCodes.contains(response.statusCode)) {
      final r = await http.Response.fromStream(response);
      print(r.statusCode);
      print(r.body);
      throw RequestException(
        'operation failed method:$method exceptionCodes:$expectedCodes statusCode:${response.statusCode}',
        response.statusCode,
      );
    }
    return http.Response.fromStream(response);
  }

  /// send the request with given [method] and [url]
  Future<http.StreamedResponse> download(
    String method,
    String url,
    List<int> expectedCodes, {
    List<int>? data,
    Map<String, String>? headers,
  }) async {
    final response = await client.send(http.Request(method, Uri.parse(url))
      ..followRedirects = false
      ..persistentConnection = true
      ..bodyBytes = data ?? Uint8List(0)
      ..headers.addAll(headers ?? {}));

    if (!expectedCodes.contains(response.statusCode)) {
      final r = await http.Response.fromStream(response);
      print(r.statusCode);
      print(r.body);
      throw RequestException(
        'operation failed method:$method exceptionCodes:$expectedCodes statusCode:${response.statusCode}',
        response.statusCode,
      );
    }
    return response;
  }
}
