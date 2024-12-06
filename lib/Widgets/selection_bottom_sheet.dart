import 'package:flutter/material.dart';
import 'package:ollama_chat/Models/ollama_request_state.dart';
import 'package:async/async.dart';

class SelectionBottomSheet<T> extends StatefulWidget {
  final Widget header;
  final Future<List<T>> Function() fetchItems;
  final T? currentSelection;

  const SelectionBottomSheet({
    super.key,
    required this.header,
    required this.fetchItems,
    required this.currentSelection,
  });

  @override
  State<SelectionBottomSheet<T>> createState() => _SelectionBottomSheetState();
}

class _SelectionBottomSheetState<T> extends State<SelectionBottomSheet<T>> {
  static final _itemsBucket = PageStorageBucket();

  T? _selectedItem;
  List<T> _items = [];

  var _state = OllamaRequestState.uninitialized;
  late CancelableOperation _fetchOperation;

  @override
  void initState() {
    super.initState();

    // Load the previous state of the items list
    _items = _itemsBucket.readState(context, identifier: widget.key) ?? [];
    _selectedItem = widget.currentSelection;

    _fetchOperation = CancelableOperation.fromFuture(_fetchItems());
  }

  @override
  void dispose() {
    // Cancel _fetchItems if it's still running
    _fetchOperation.cancel();

    super.dispose();
  }

  Future<void> _fetchItems() async {
    setState(() {
      _state = OllamaRequestState.loading;
    });

    try {
      _items = await widget.fetchItems();

      _state = OllamaRequestState.success;

      if (mounted) {
        // Save the current state of the items list
        _itemsBucket.writeState(context, _items, identifier: widget.key);
      }
    } catch (e) {
      _state = OllamaRequestState.error;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              widget.header,
              const Spacer(),
              if (_items.isNotEmpty && _state == OllamaRequestState.loading)
                const CircularProgressIndicator()
            ],
          ),
          const Divider(),
          Expanded(
            child: _buildBody(context),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(widget.currentSelection);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_selectedItem != null) {
                    Navigator.of(context).pop(_selectedItem);
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

  Widget _buildBody(BuildContext context) {
    if (_state == OllamaRequestState.error) {
      return Center(
        child: Text(
          'An error occurred while fetching the items.'
          '\nCheck your server connection and try again.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    } else if (_state == OllamaRequestState.loading && _items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_state == OllamaRequestState.success || _items.isNotEmpty) {
      if (_items.isEmpty) {
        return Center(child: Text('No items found.'));
      }

      return RefreshIndicator(
        onRefresh: () async {
          _fetchOperation = CancelableOperation.fromFuture(_fetchItems());
        },
        child: ListView.builder(
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
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

Future<T> showSelectionBottomSheet<T>({
  ValueKey? key,
  required BuildContext context,
  required Widget header,
  required Future<List<T>> Function() fetchItems,
  required T currentSelection,
}) async {
  return await showModalBottomSheet(
    context: context,
    builder: (context) {
      return SelectionBottomSheet(
        key: key,
        header: header,
        fetchItems: fetchItems,
        currentSelection: currentSelection,
      );
    },
    isDismissible: false,
    enableDrag: false,
  );
}
