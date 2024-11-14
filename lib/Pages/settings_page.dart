import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ollama_chat/Providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ollama_chat/Models/ollama_request_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  OllamaRequestState _requestState = OllamaRequestState.uninitialized;

  final _serverAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final serverAddress = prefs.getString('serverAddress');

    if (serverAddress != null) {
      _serverAddressController.text = serverAddress;
      _handleConnect();
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
                      : () {
                          _handleConnect(context: context);
                        },
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

  _handleConnect({BuildContext? context}) async {
    final serverAddress = _serverAddressController.text;

    setState(() {
      _requestState = OllamaRequestState.loading;
    });

    final state = await _establishServerConnection(Uri.parse(serverAddress));

    setState(() {
      _requestState = state;
    });

    if (state == OllamaRequestState.success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('serverAddress', serverAddress);

      if (context != null) {
        // TODO: Do not use context here
        Provider.of<ChatProvider>(context, listen: false)
            .updateOllamaServiceAddress();
      }
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
