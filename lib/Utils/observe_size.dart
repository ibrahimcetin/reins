import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ObserveSize extends SingleChildRenderObjectWidget {
  final Function(Size?, Size) onSizeChanged;

  const ObserveSize({
    super.key,
    required this.onSizeChanged,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderObserveSize(onSizeChanged);
  }
}

class _RenderObserveSize extends RenderProxyBox {
  final Function(Size?, Size) onSizeChanged;

  _RenderObserveSize(this.onSizeChanged);

  Size? _previousSize;

  @override
  void performLayout() {
    super.performLayout();

    final newSize = (child?.size ?? size);

    if (_previousSize != newSize) {
      onSizeChanged(_previousSize, newSize);
      _previousSize = newSize;
    }
  }
}
