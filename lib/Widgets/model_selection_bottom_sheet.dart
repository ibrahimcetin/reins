import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:reins/Models/model_capabilities.dart';

import 'package:reins/Models/ollama_model.dart';
import 'package:reins/Models/ollama_request_state.dart';
import 'package:reins/Providers/chat_provider.dart';
import 'package:reins/Widgets/ollama_bottom_sheet_header.dart';

class ModelSelectionBottomSheet extends StatefulWidget {
  final String title;
  final String? currentModelName;

  const ModelSelectionBottomSheet({
    super.key,
    required this.title,
    this.currentModelName,
  });

  @override
  State<ModelSelectionBottomSheet> createState() => _ModelSelectionBottomSheetState();
}

class _ModelSelectionBottomSheetState extends State<ModelSelectionBottomSheet> {
  static final _modelsBucket = PageStorageBucket();

  late final ChatProvider _chatProvider;

  OllamaModel? _selectedModel;
  List<OllamaModel> _models = [];

  var _state = OllamaRequestState.uninitialized;
  late CancelableOperation _fetchOperation;

  /// Cache key derived from server address
  String get _cacheKey => Hive.box('settings').get('serverAddress') ?? 'default';

  @override
  void initState() {
    super.initState();

    _chatProvider = context.read<ChatProvider>();

    // Load the previous state of the models list
    _models = _modelsBucket.readState(context, identifier: _cacheKey) ?? [];
    _selectedModel = _findModelByName(widget.currentModelName);

    _fetchOperation = CancelableOperation.fromFuture(_fetchModels());
  }

  @override
  void dispose() {
    _fetchOperation.cancel();
    super.dispose();
  }

  OllamaModel? _findModelByName(String? name) {
    if (name == null) return null;
    try {
      return _models.firstWhere((m) => m.name == name);
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchModels() async {
    setState(() {
      _state = OllamaRequestState.loading;
    });

    try {
      _models = await _chatProvider.fetchAvailableModels();
      _state = OllamaRequestState.success;

      // Update selection if we were searching by name (cache was empty)
      if (_selectedModel == null && widget.currentModelName != null) {
        _selectedModel = _findModelByName(widget.currentModelName);
      }

      if (mounted) {
        _modelsBucket.writeState(context, _models, identifier: _cacheKey);
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
              Expanded(child: OllamaBottomSheetHeader(title: widget.title)),
              if (_models.isNotEmpty && _state == OllamaRequestState.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          const Divider(),
          Expanded(child: _buildBody(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: _selectedModel != null ? () => Navigator.of(context).pop(_selectedModel) : null,
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
          'An error occurred while fetching models.'
          '\nCheck your server connection and try again.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      );
    } else if (_state == OllamaRequestState.loading && _models.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    } else if (_state == OllamaRequestState.success || _models.isNotEmpty) {
      if (_models.isEmpty) {
        return const Center(child: Text('No models found.'));
      }

      return RefreshIndicator(
        onRefresh: () async {
          _fetchOperation = CancelableOperation.fromFuture(_fetchModels());
        },
        child: RadioGroup<OllamaModel>(
          groupValue: _selectedModel,
          onChanged: (model) => setState(() => _selectedModel = model),
          child: ListView.builder(
            itemCount: _models.length,
            itemBuilder: (context, index) {
              return _ModelListTile(model: _models[index]);
            },
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class _ModelListTile extends StatelessWidget {
  final OllamaModel model;

  const _ModelListTile({required this.model});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capabilities = model.capabilities;

    return RadioListTile<OllamaModel>(
      value: model,
      title: Text(model.name),
      subtitle: model.parameterSize.isNotEmpty
          ? Text(
              model.parameterSize,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          : null,
      secondary: capabilities != null
          ? Row(
              spacing: 8,
              mainAxisSize: MainAxisSize.min,
              children: _buildCapabilityChips(capabilities),
            )
          : null,
    );
  }

  List<Widget> _buildCapabilityChips(ModelCapabilities capabilities) {
    final chips = <Widget>[];

    if (capabilities.vision) {
      chips.add(_CapabilityChip(
        icon: Icons.visibility_outlined,
        label: 'Vision',
      ));
    }
    if (capabilities.tools) {
      chips.add(_CapabilityChip(
        icon: Icons.build_outlined,
        label: 'Tools',
      ));
    }
    if (capabilities.thinking) {
      chips.add(_CapabilityChip(
        icon: Icons.lightbulb_outline,
        label: 'Thinking',
      ));
    }

    return chips;
  }
}

class _CapabilityChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CapabilityChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Icon(icon, size: 22),
    );
  }
}

/// Shows a model selection bottom sheet and returns the selected model.
///
/// Returns the selected [OllamaModel], or the current model if cancelled.
Future<OllamaModel?> showModelSelectionBottomSheet({
  required BuildContext context,
  required String title,
  String? currentModelName,
}) async {
  return await showModalBottomSheet<OllamaModel?>(
    context: context,
    builder: (context) {
      return ModelSelectionBottomSheet(title: title, currentModelName: currentModelName);
    },
    isDismissible: false,
    enableDrag: false,
  );
}
