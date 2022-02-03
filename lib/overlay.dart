import 'package:flutter/material.dart';
import 'package:progress_indicators/progress_indicators.dart';

class TutorialOverlay extends ModalRoute<void> {
  bool saved = false;

  TutorialOverlay({Key? key, required this.saved});

  @override
  Duration get transitionDuration => Duration(milliseconds: 200);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.85);

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // This makes sure that text and other content follows the material style
    return Material(
      type: MaterialType.transparency,
      // make sure that the overlay content is not cut off
      child: SafeArea(
        child: _buildOverlayContent(context),
      ),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          saved
              ? Icon(Icons.check_circle_outline_rounded,
                  color: Colors.green, size: 32)
              : Container(),
          saved
              ? Text(
                  "Saved!",
                  style: const TextStyle(color: Colors.white, fontSize: 30.0),
                )
              : FadingText(
                  '   Saving...',
                  style: const TextStyle(color: Colors.white, fontSize: 30.0),
                ),
          saved
              ? TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Dismiss'),
                  style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(Colors.green)),
                )
              : Container(),
          Row(
            children: [Text("Share buttons")],
          ),
        ],
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // You can add your own animations for the overlay content
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  }

  @override
  // TODO: implement barrierLabel
  String? get barrierLabel => "";
}
