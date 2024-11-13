import 'package:flutter/material.dart';

// TODO: Make this generic

class ChatModelSelectionBottomSheet extends StatefulWidget {
  final String title;

  final List<String> values;
  final String? currentSelection;

  final Function(String) onSelection;

  const ChatModelSelectionBottomSheet({
    super.key,
    required this.title,
    required this.values,
    required this.currentSelection,
    required this.onSelection,
  });

  @override
  State<ChatModelSelectionBottomSheet> createState() =>
      _ChatModelSelectionBottomSheetState();
}

class _ChatModelSelectionBottomSheetState
    extends State<ChatModelSelectionBottomSheet> {
  String? _selectedLlmModel;

  @override
  void initState() {
    super.initState();

    _selectedLlmModel = widget.currentSelection;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(
                      "assets/images/ollama.png",
                      height: 48,
                    ),
                  ),
                ),
                Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  ...widget.values.map((model) {
                    return RadioListTile(
                      title: Text(model),
                      value: model,
                      groupValue: _selectedLlmModel,
                      onChanged: (value) {
                        setState(() {
                          _selectedLlmModel = value;
                        });
                      },
                      secondary: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.info_outline),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (_selectedLlmModel != null) {
                      widget.onSelection(_selectedLlmModel!);
                      Navigator.of(context).pop();
                    } else {
                      // Do nothing
                    }
                  },
                  child: const Text('Select'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
