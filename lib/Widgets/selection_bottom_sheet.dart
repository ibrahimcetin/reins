import 'package:flutter/material.dart';
import 'package:ollama_chat/Models/ollama_request_state.dart';

class SelectionBottomSheet<T> extends StatefulWidget {
  final Widget title;
  final Future<List<T>> Function() fetchItems;
  final T? currentSelection;
  final void Function(T) onSelection;

  const SelectionBottomSheet({
    super.key,
    required this.title,
    required this.fetchItems,
    required this.currentSelection,
    required this.onSelection,
  });

  @override
  State<SelectionBottomSheet<T>> createState() => _SelectionBottomSheetState();
}

class _SelectionBottomSheetState<T> extends State<SelectionBottomSheet<T>> {
  T? _selectedItem;
  List<T> _items = [];

  var _state = OllamaRequestState.loading;

  @override
  void initState() {
    super.initState();

    _selectedItem = widget.currentSelection;

    _fetchItems();
  }

  Future<void> _fetchItems() async {
    _items = await widget.fetchItems();

    setState(() {
      _state = OllamaRequestState.success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          widget.title,
          const Divider(),
          Expanded(
            // TODO: Add error case
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];

                      return RadioListTile(
                        title: Text(item.toString()),
                        value: item,
                        groupValue: _selectedItem,
                        onChanged: (value) {
                          setState(() {
                            _selectedItem = value;
                          });
                        },
                      );
                    },
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
                  if (_selectedItem != null) {
                    widget.onSelection(_selectedItem as T);
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Select'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get isLoading => _state == OllamaRequestState.loading;
}
