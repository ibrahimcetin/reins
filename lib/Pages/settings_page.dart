import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:ollama_chat/Models/ollama_request_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsBox = Hive.box('settings');

  OllamaRequestState _requestState = OllamaRequestState.uninitialized;

  final _serverAddressController = TextEditingController();

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _serverAddressController,
              onChanged: (_) {
                setState(() {
                  _requestState = OllamaRequestState.uninitialized;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Ollama Server Address',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
        ),
      ),
    );
  }

  _handleConnectButton() async {
    final serverAddress = _serverAddressController.text;

    setState(() {
      _requestState = OllamaRequestState.loading;
    });

    final state = await _establishServerConnection(Uri.parse(serverAddress));

    setState(() {
      _requestState = state;
    });

    if (state == OllamaRequestState.success) {
      _settingsBox.put('serverAddress', serverAddress);
    }
  }

  Future<OllamaRequestState> _establishServerConnection(
    Uri serverAddress,
  ) async {
    try {
      final response = await http.get(serverAddress);

      if (response.body == "Ollama is running") {
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
