import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:ollama_chat/Models/ollama_request_state.dart';

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
              _requestState = OllamaRequestState.uninitialized;
            });
          },
          decoration: InputDecoration(
            labelText: 'Ollama Server Address',
            border: OutlineInputBorder(),
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
    final serverAddress = _serverAddressController.text;

    setState(() {
      _requestState = OllamaRequestState.loading;
    });

    final state = await _establishServerConnection(Uri.parse(serverAddress));

    if (mounted == false) {
      return;
    }

    setState(() {
      _requestState = state;
    });

    if (state == OllamaRequestState.success) {
      final url = Uri.parse(serverAddress);
      final formattedServerAddress = "${url.scheme}://${url.host}:${url.port}";

      _settingsBox.put('serverAddress', formattedServerAddress);
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
