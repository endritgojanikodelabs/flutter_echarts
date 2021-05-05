library flutter_echarts;

// --- FIX_BLINK ---
import 'dart:io' show Platform;
// --- FIX_BLINK ---

import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

import 'package:webview_flutter/webview_flutter.dart';

/// <!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=0, target-densitydpi=device-dpi" /><style type="text/css">body,html,#chart{height: 100%;width: 100%;margin: 0px;}div {-webkit-tap-highlight-color:rgba(255,255,255,0);}</style></head><body><div id="chart" /></body></html>
/// 'data:text/html;base64,' + base64Encode(const Utf8Encoder().convert( /* STRING ABOVE */ ))
class Echarts extends StatefulWidget {
  Echarts(
      {Key? key,
      required this.option,
      this.onMessage,
      this.theme,
      this.captureAllGestures = false,
      this.captureHorizontalGestures = false,
      this.captureVerticalGestures = false,
      this.onLoad,
      this.reloadAfterInit = false})
      : super(key: key);

  final String option;

  final void Function(String message)? onMessage;

  final String? theme;

  final bool captureAllGestures;

  final bool captureHorizontalGestures;

  final bool captureVerticalGestures;

  final void Function(WebViewController)? onLoad;

  final bool reloadAfterInit;

  @override
  _EchartsState createState() => _EchartsState();
}

class _EchartsState extends State<Echarts> {
  WebViewController? _controller;

  String? _currentOption;

  // --- FIX_BLINK ---
  double _opacity = Platform.isAndroid ? 0.0 : 1.0;

  // --- FIX_BLINK ---

  @override
  void initState() {
    super.initState();
    _currentOption = widget.option;

    if (widget.reloadAfterInit) {
      new Future.delayed(const Duration(milliseconds: 100), () {
        _controller?.reload();
      });
    }
  }

  void init() async {
    await _controller?.evaluateJavascript('''
      chart.setOption($_currentOption, true);
    ''');
    if (widget.onLoad != null) {
      widget.onLoad!(_controller!);
    }
  }

  Set<Factory<OneSequenceGestureRecognizer>> getGestureRecognizers() {
    Set<Factory<OneSequenceGestureRecognizer>> set = Set();
    if (this.widget.captureAllGestures ||
        this.widget.captureHorizontalGestures) {
      set.add(Factory<HorizontalDragGestureRecognizer>(() {
        return HorizontalDragGestureRecognizer()
          ..onStart = (DragStartDetails details) {}
          ..onUpdate = (DragUpdateDetails details) {}
          ..onDown = (DragDownDetails details) {}
          ..onCancel = () {}
          ..onEnd = (DragEndDetails details) {};
      }));
    }
    if (this.widget.captureAllGestures || this.widget.captureVerticalGestures) {
      set.add(Factory<VerticalDragGestureRecognizer>(() {
        return VerticalDragGestureRecognizer()
          ..onStart = (DragStartDetails details) {}
          ..onUpdate = (DragUpdateDetails details) {}
          ..onDown = (DragDownDetails details) {}
          ..onCancel = () {}
          ..onEnd = (DragEndDetails details) {};
      }));
    }
    return set;
  }

  void update(String preOption) async {
    _currentOption = widget.option;
    if (_currentOption != preOption) {
      await _controller?.evaluateJavascript('''
        try {
          chart.setOption($_currentOption, true);
        } catch(e) {
        }
      ''');
    }
  }

  @override
  void didUpdateWidget(Echarts oldWidget) {
    super.didUpdateWidget(oldWidget);
    update(oldWidget.option);
  }

  // --- FIX_IOS_LEAK ---
  @override
  void dispose() {
    if (Platform.isIOS) {
      _controller?.clearCache();
    }
    super.dispose();
  }

  // --- FIX_IOS_LEAK ---

  @override
  Widget build(BuildContext context) {
    // --- FIX_BLINK ---
    return Opacity(
        opacity: _opacity,
        // --- FIX_BLINK ---
        child: WebView(
            initialUrl:
                'https://development.kodelabs.com/bms/assets/echarts.html',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
            },
            onPageFinished: (String url) {
              // --- FIX_BLINK ---
              if (Platform.isAndroid) {
                setState(() {
                  _opacity = 1.0;
                });
              }
              // --- FIX_BLINK ---
              init();
            },
            javascriptChannels: <JavascriptChannel>[
              JavascriptChannel(
                  name: 'Messager',
                  onMessageReceived: (JavascriptMessage javascriptMessage) {
                    if (widget.onMessage != null) {
                      widget.onMessage!(javascriptMessage.message);
                    }
                  }),
            ].toSet(),
            gestureRecognizers: getGestureRecognizers()));
  }
}
