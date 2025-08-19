import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:reins/Models/ollama_exception.dart';
import 'package:reins/Models/ollama_request_state.dart';
import 'package:reins/Widgets/ollama_bottom_sheet_header.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ServerSettings extends StatefulWidget {
  final bool autoFocusServerAddress;

  const ServerSettings({super.key, this.autoFocusServerAddress = false});

  @override
  State<ServerSettings> createState() => _ServerSettingsState();
}

class _ServerSettingsState extends State<ServerSettings> {
  final _settingsBox = Hive.box('settings');

  final _serverAddressController = TextEditingController();

  OllamaRequestState _requestState = OllamaRequestState.uninitialized;
  get _isLoading => _requestState == OllamaRequestState.loading;

  String? _serverAddressErrorText;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  _initialize() {
    final serverAddress = _settingsBox.get('serverAddress');

    if (serverAddress != null) {
      _serverAddressController.text = serverAddress;
      _handleConnectButton();
    }
  }

  @override
  void dispose() {
    _serverAddressController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Server',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextField(
          autofocus: widget.autoFocusServerAddress,
          controller: _serverAddressController,
          keyboardType: TextInputType.url,
          onChanged: (_) {
            setState(() {
              _serverAddressErrorText = null;
              _requestState = OllamaRequestState.uninitialized;
            });
          },
          decoration: InputDecoration(
            labelText: 'Ollama Server Address',
            border: OutlineInputBorder(),
            errorText: _serverAddressErrorText,
            suffixIcon: IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () => _showOllamaInfoBottomSheet(context),
            ),
          ),
          onTapOutside: (PointerDownEvent event) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSearchLocalNetwork,
              child: const Text('Search Local Network'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleConnectButton,
              child: _ConnectionStatusIndicator(
                color: _connectionStatusColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color get _connectionStatusColor {
    switch (_requestState) {
      case OllamaRequestState.error:
        return Colors.red;
      case OllamaRequestState.loading:
        return Colors.orange;
      case OllamaRequestState.success:
        return Colors.green;
      case OllamaRequestState.uninitialized:
        return Colors.grey;
    }
  }

  _handleConnectButton() async {
    setState(() {
      _serverAddressErrorText = null;
      _requestState = OllamaRequestState.loading;
    });

    try {
      // Validate the server address.
      final newAddress = _validateServerAddress(_serverAddressController.text);
      // Establish a connection to the server.
      final result = await _establishServerConnection(Uri.parse(newAddress));

      if (!mounted) return;

      _requestState = result.$1;
      _saveServerAddressWith(result);
    } on OllamaException catch (error) {
      _serverAddressErrorText = error.message;
      _requestState = OllamaRequestState.error;
    } catch (_) {
      _serverAddressErrorText =
          'Invalid URL format. Use: http(s)://<host>:<port>';
      _requestState = OllamaRequestState.error;
    } finally {
      setState(() {});
    }
  }

  void _saveServerAddressWith((OllamaRequestState, Uri) result) {
    final state = result.$1;
    final newAddress = result.$2.toString();

    final currentAddress = _settingsBox.get('serverAddress');
    if (state == OllamaRequestState.success && newAddress != currentAddress) {
      _settingsBox.put('serverAddress', newAddress);
    }
  }

  /// Establishes a connection to the Ollama server.
  ///
  /// Returns a tuple of the request state and the given server address.
  static Future<(OllamaRequestState, Uri)> _establishServerConnection(
    Uri serverAddress,
  ) async {
    try {
      final response =
          await http.get(serverAddress).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        return (OllamaRequestState.success, serverAddress);
      } else {
        return (OllamaRequestState.error, serverAddress);
      }
    } catch (e) {
      return (OllamaRequestState.error, serverAddress);
    }
  }

  String _validateServerAddress(String address) {
    if (address.isEmpty) {
      throw OllamaException('Please enter a server address.');
    }

    final url = Uri.parse(address);

    if (url.scheme.isEmpty) {
      throw OllamaException(
        'Please include the scheme. e.g. http://localhost:11434',
      );
    }

    // If user don't include the scheme and just enter host and port like 'localhost:11434'.
    // The parser will consider the host as the scheme, so host will be empty. But actually the scheme is empty.
    if (url.scheme != 'http' && url.scheme != 'https' && url.host.isEmpty) {
      throw OllamaException(
        'Please include the scheme. e.g. http://localhost:11434',
      );
    }

    if (url.host.isEmpty) {
      throw OllamaException(
        'Please include the host. e.g. http://localhost:11434',
      );
    }

    if (url.scheme != 'http' && url.scheme != 'https') {
      throw OllamaException(
        'Invalid scheme. Only http and https are supported.',
      );
    }

    final String formattedAddress = "${url.scheme}://${url.host}${url.hasPort ? ":${url.port}" : ""}${url.path}";
    return formattedAddress;
  }

  void _showOllamaInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return _OllamaInfoBottomSheet();
      },
    );
  }

  void _handleSearchLocalNetwork() async {
    setState(() {
      _serverAddressErrorText = null;
      _requestState = OllamaRequestState.loading;
    });

    try {
      final result = await Isolate.run(() => _searchLocalNetwork());
      final foundAddress = result.$2.toString();

      if (!mounted) return;

      // Update the server address text field with the found address.
      _serverAddressController.text = foundAddress;

      _requestState = result.$1;
      _saveServerAddressWith(result);
    } on OllamaException catch (e) {
      _serverAddressErrorText = e.message;
      _requestState = OllamaRequestState.error;
    } catch (e) {
      _serverAddressErrorText = 'Something went wrong while searching.';
      _requestState = OllamaRequestState.error;
    } finally {
      setState(() {});
    }
  }

  static Future<(OllamaRequestState, Uri)> _searchLocalNetwork() async {
    final networkInterfaces = await NetworkInterface.list(
      includeLoopback: true,
      type: InternetAddressType.IPv4,
    );

    final futures = <Future<(OllamaRequestState, Uri)>>[];
    for (var interface in networkInterfaces) {
      for (var address in interface.addresses) {
        if (address.isLoopback) {
          final url = Uri.parse('http://${address.address}:11434');
          futures.add(_establishServerConnection(url));
        } else {
          final segments = address.address.split('.');
          for (int i = 1; i < 255; i++) {
            final url = Uri.parse(
              'http://${segments[0]}.${segments[1]}.${segments[2]}.$i:11434',
            );
            futures.add(_establishServerConnection(url));
          }
        }
      }
    }

    final results = await Future.wait(futures);

    final result = results.firstWhere(
      (result) => result.$1 == OllamaRequestState.success,
      orElse: () =>
          throw OllamaException('No Ollama server found on the local network.'),
    );

    return result;
  }
}

class _ConnectionStatusIndicator extends StatelessWidget {
  final Color color;

  const _ConnectionStatusIndicator({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Connect'),
        const SizedBox(width: 10),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _OllamaInfoBottomSheet extends StatelessWidget {
  const _OllamaInfoBottomSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      minimum: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OllamaBottomSheetHeader(title: 'What is Ollama?'),
          Divider(),
          Expanded(
            child: ListView(
              children: [
                MarkdownBody(
                  data:
                      "Ollama is a free platform that enables you to run advanced large language models (LLMs) like Llama 3.3, Phi 3, Mistral, Gemma 2, and more directly on your local machine. This setup enhances privacy, security, and control over your AI interactions. Ollama also allows you to customize and create your own models.\n\nTo get started with Ollama, visit their official website: [ollama.com](https://ollama.com). Here, you can explore various models and download the platform to begin using Ollama.",
                  styleSheet: MarkdownStyleSheet(
                    textScaler: TextScaler.linear(1.18),
                  ),
                  onTapLink: (_, href, __) => launchUrlString(href!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
