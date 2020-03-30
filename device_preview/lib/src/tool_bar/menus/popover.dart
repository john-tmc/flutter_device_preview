import 'package:device_preview/src/utilities/media_query_observer.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

import '../../device_preview.dart';
import '../../utilities/position.dart';
import '../tool_bar_theme.dart';

class Popover extends StatefulWidget {
  final Widget child;
  final String title;
  final IconData icon;
  final Size size;
  final WidgetBuilder builder;

  const Popover({
    this.size,
    @required this.title,
    @required this.icon,
    @required this.child,
    @required this.builder,
  });

  static void open(BuildContext context) {
    final state = context.findAncestorStateOfType<_PopoverState>();
    state.open();
  }

  static void close(BuildContext context) {
    final state = context.findAncestorStateOfType<_PopoverState>();
    state.close();
  }

  @override
  _PopoverState createState() => _PopoverState();
}

class _PopoverState extends State<Popover> {
  final _key = GlobalKey();
  List<OverlayEntry> _overlayEntries = [];
  bool _isOpen = false;

  void open() {
    final device = DevicePreview.of(context);
    if (!_isOpen) {
      final barrier = OverlayEntry(
        opaque: false,
        builder: (context) => _PopOverBarrier(
          () => close(),
        ),
      );

      final popover = OverlayEntry(
        opaque: false,
        builder: (context) => MediaQueryObserver(
          child: DevicePreviewProvider(
            availableDevices: device.availableDevices,
            data: device.data,
            mediaQuery: device.mediaQuery,
            child: _PopOverContainer(
              child: Column(
                children: <Widget>[
                  _PopOverHeader(
                    title: widget.title,
                    icon: widget.icon,
                  ),
                  Expanded(
                    child: widget.builder(context),
                  ),
                ],
              ),
              size: widget.size ?? Size(300, 500),
              startPosition: _key.absolutePosition,
            ),
          ),
        ),
      );
      _overlayEntries.add(barrier);
      _overlayEntries.add(popover);
      Overlay.of(context).insertAll(_overlayEntries);
      _isOpen = true;
    }
  }

  void close() {
    if (_isOpen) {
      for (var item in _overlayEntries) {
        item.remove();
      }
      _isOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(key: _key, child: widget.child);
  }
}

class _PopOverContainer extends StatefulWidget {
  final Rect startPosition;
  final Size size;
  final Widget child;

  _PopOverContainer({
    @required this.child,
    @required this.startPosition,
    @required this.size,
  });

  @override
  __PopOverContainerState createState() => __PopOverContainerState();
}

class __PopOverContainerState extends State<_PopOverContainer>
    with WidgetsBindingObserver {
  bool _isStarted;

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  @override
  void initState() {
    // Centered bottom

    _isStarted = false;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        _isStarted = true;
      });
    });
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const spacing = 10.0;
    final duration = const Duration(milliseconds: 80);
    final toolBarStyle = DevicePreviewToolBarTheme.of(context);
    final media = MediaQuery.of(context);
    final removeBottomOffset = media.viewInsets.bottom > 0.0;

    var width = math.min(widget.size.width, media.size.width - 2 * spacing);
    final top = widget.startPosition.top - widget.size.height - 5.0;
    var height = math.min(widget.size.height, media.size.height - top);
    var left = math.max(10.0, widget.startPosition.center.dx - width / 2);
    left = math.min(left, media.size.width - spacing - width);

    final bounds = _isStarted
        ? Rect.fromLTWH(left, top, width, height)
        : widget.startPosition;

    return AnimatedPositioned(
      duration: duration,
      left: bounds.left,
      top: bounds.top - media.viewInsets.bottom,
      width: bounds.width,
      height: math.min(
          bounds.height,
          media.size.height -
              media.viewInsets.vertical -
              media.viewPadding.vertical),
      child: AnimatedOpacity(
        duration: duration,
        opacity: _isStarted ? 1.0 : 0.0,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          transform: _isStarted
              ? Matrix4.identity()
              : Matrix4.translationValues(0, 6.0, 0),
          decoration: BoxDecoration(
            color: toolBarStyle.buttonBackgroundColor,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _PopOverBarrier extends StatelessWidget {
  final GestureTapCallback onTap;

  _PopOverBarrier(this.onTap);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onTap,
        child: Container(color: const Color(0x06000000)),
      ),
    );
  }
}

class _PopOverHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  _PopOverHeader({
    @required this.title,
    @required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final toolBarStyle = DevicePreviewToolBarTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: toolBarStyle.backgroundColor,
        borderRadius: BorderRadius.circular(6.0),
      ),
      padding: EdgeInsets.all(10.0),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 12.0,
            color: toolBarStyle.foregroundColor,
          ),
          SizedBox(
            width: 6.0,
          ),
          Text(
            title,
            style: TextStyle(
              color: toolBarStyle.foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}