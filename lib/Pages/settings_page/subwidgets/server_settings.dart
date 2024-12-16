import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:reins/Models/ollama_request_state.dart';

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
              onPressed: () {},
              icon: Icon(Icons.info_outline),
            ),
          ),
          onTapOutside: (PointerDownEvent event) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // TODO: Add search local network button
            ElevatedButton(
              onPressed: _requestState == OllamaRequestState.loading
                  ? null
                  : _handleConnectButton,
              child: Row(
                children: [
                  const Text('Connect'),
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _connectionStatusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  _handleConnectButton() async {
    setState(() {
      _requestState = OllamaRequestState.loading;
    });

    try {
      final newAddress = _validateServerAddress(_serverAddressController.text);

      final state = await _establishServerConnection(Uri.parse(newAddress));

      if (!mounted) {
        return;
      }

      setState(() {
        _requestState = state;
      });

      final currentAddress = _settingsBox.get('serverAddress');
      if (state == OllamaRequestState.success && newAddress != currentAddress) {
        _settingsBox.put('serverAddress', newAddress);
      }
    } on String catch (error) {
      setState(() {
        _serverAddressErrorText = error;
        _requestState = OllamaRequestState.error;
      });
    } catch (_) {
      setState(() {
        _serverAddressErrorText =
            'Invalid URL format. Use: http(s)://<host>:<port>.';
        _requestState = OllamaRequestState.error;
      });
    }
  }

  Future<OllamaRequestState> _establishServerConnection(
    Uri serverAddress,
  ) async {
    try {
      final response =
          await http.get(serverAddress).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body == "Ollama is running") {
        return OllamaRequestState.success;
      } else {
        return OllamaRequestState.error;
      }
    } catch (e) {
      return OllamaRequestState.error;
    }
  }

  String _validateServerAddress(String address) {
    if (address.isEmpty) {
      throw 'Please enter a server address.';
    }

    final url = Uri.parse(address);

    if (url.scheme.isEmpty) {
      throw 'Please include the scheme. e.g. http://localhost:11434';
    }

    // If user don't include the scheme and just enter host and port like 'localhost:11434'.
    // The parser will consider the host as the scheme, so host will be empty. But actually the scheme is empty.
    if (url.scheme != 'http' && url.scheme != 'https' && url.host.isEmpty) {
      throw 'Please include the scheme. e.g. http://localhost:11434';
    }

    if (url.host.isEmpty) {
      throw 'Please include the host. e.g. http://localhost:11434';
    }

    if (url.scheme != 'http' && url.scheme != 'https') {
      throw 'Invalid scheme. Only http and https are supported.';
    }

    String formattedAddress = "${url.scheme}://${url.host}";

    if (url.hasPort) {
      formattedAddress += ":${url.port}";
    }

    return formattedAddress;
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
}
