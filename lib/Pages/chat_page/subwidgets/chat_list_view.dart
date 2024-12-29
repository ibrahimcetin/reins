import 'package:flutter/material.dart';
import 'package:reins/Models/ollama_message.dart';
import 'package:reins/Widgets/chat_bubble.dart';
import 'package:shimmer/shimmer.dart';

class ChatListView extends StatefulWidget {
  final List<OllamaMessage> messages;
  final bool isAwaitingReply;
  final Widget? error;
  final double? bottomPadding;

  const ChatListView({
    super.key,
    required this.messages,
    required this.isAwaitingReply,
    this.error,
    this.bottomPadding,
  });

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  static final _scrollOffsetBucket = PageStorageBucket();

  late final ScrollController _scrollController;
  bool _isScrollToBottomButtonVisible = false;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController(
      initialScrollOffset: _readScrollOffset(),
    );

    _scrollController.addListener(() {
      _updateScrollToBottomButtonVisibility();
    });
  }

  @override
  void didUpdateWidget(covariant ChatListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Add to the post frame callback to ensure that the scroll offset is
    // read after the widget has been updated.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Update the button visibility when the user switches chats,
      // regenerates a message or delete a message.
      _updateScrollToBottomButtonVisibility();
    });
  }

  @override
  void deactivate() {
    _writeScrollOffset();

    super.deactivate();
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CustomScrollView(
          controller: _scrollController,
          reverse: true,
          slivers: [
            if (widget.bottomPadding != null)
              SliverPadding(
                padding: EdgeInsets.only(bottom: widget.bottomPadding!),
              ),
            if (widget.error != null)
              SliverToBoxAdapter(
                child: widget.error,
              ),
            if (widget.isAwaitingReply)
              SliverToBoxAdapter(
                child: Shimmer.fromColors(
                  // TODO: Play with the colors to make it look better
                  baseColor: Theme.of(context).colorScheme.onPrimary,
                  highlightColor: Theme.of(context).colorScheme.onSurface,
                  period: Duration(milliseconds: 2500),
                  child: ListTile(
                    title: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text("Thinking"),
                    ),
                  ),
                ),
              ),
            SliverList.builder(
              key: widget.key,
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final message =
                    widget.messages[widget.messages.length - index - 1];

                return ChatBubble(message: message);
              },
            ),
          ],
        ),
        if (_isScrollToBottomButtonVisible)
          IconButton(
            onPressed: _scrollToBottom,
            icon: const Icon(Icons.arrow_downward_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
            ),
          ),
      ],
    );
  }

  void _updateScrollToBottomButtonVisibility() {
    if (_scrollController.position.pixels > 100 &&
        !_isScrollToBottomButtonVisible) {
      setState(() {
        _isScrollToBottomButtonVisible = true;
      });
    }

    if (_scrollController.position.pixels < 100 &&
        _isScrollToBottomButtonVisible) {
      setState(() {
        _isScrollToBottomButtonVisible = false;
      });
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  double _readScrollOffset() {
    return _scrollOffsetBucket.readState(context, identifier: widget.key) ??
        0.0;
  }

  void _writeScrollOffset() {
    if (widget.key == null) return;

    _scrollOffsetBucket.writeState(
      context,
      _scrollController.offset,
      identifier: widget.key,
    );
  }
}
