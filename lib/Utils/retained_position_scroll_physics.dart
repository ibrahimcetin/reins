import 'package:flutter/material.dart';

class WidgetSizeProxy {
  double deltaHeight = 0.0;
}

class RetainedPositionScrollPhysics extends ScrollPhysics {
  const RetainedPositionScrollPhysics({
    super.parent,
    required this.widgetSizeProxy,
  });

  final WidgetSizeProxy widgetSizeProxy;

  @override
  ScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return RetainedPositionScrollPhysics(
      parent: ancestor,
      widgetSizeProxy: widgetSizeProxy,
    );
  }

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    final adjustPosition = super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );

    if (isScrolling && velocity.abs() > 1) {
      // If the user really wants to scroll, return the original position
      // the velocity will be 0 when the user holds the screen and scrolls
      // but when the user scrolls fast, the velocity will be greater than 1
      return adjustPosition;
    } else if (adjustPosition <= 44) {
      // 44 is just a threshold to adjust the position when the user scrolls to the bottom
      // if the user scrolls to the bottom, the adjustPosition is 0
      // so we need to return the original position
      return adjustPosition;
    } else {
      // Add the delta height to keep the scroll position stable
      return adjustPosition + widgetSizeProxy.deltaHeight;
    }
  }
}
