import 'package:flutter/material.dart';
import 'package:ollama_chat/Providers/chat_provider.dart';
import 'package:provider/provider.dart';

class ChatBottomSheet extends StatefulWidget {
  const ChatBottomSheet({super.key});

  @override
  State<ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<ChatBottomSheet> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Configure Chat',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select LLM Model',
                  border: OutlineInputBorder(),
                ),
                items: <String>['Model 1', 'Model 2', 'Model 3']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  // Handle model selection
                },
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Temperature"),
                  Slider(
                    value: _sliderValue,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    label: _sliderValue.toStringAsFixed(2),
                    onChanged: (double value) {
                      setState(() {
                        _sliderValue = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  Provider.of<ChatProvider>(context, listen: false)
                      .deleteChat();

                  Navigator.pop(context);
                },
                child: const Text('Delete Chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
