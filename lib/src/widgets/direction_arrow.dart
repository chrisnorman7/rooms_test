import 'package:flutter/material.dart';
import 'package:flutter_audio_games/flutter_audio_games.dart';

/// A directional arrow.
class DirectionArrow extends StatelessWidget {
  /// Create an instance.
  const DirectionArrow({
    required this.getDirection,
    required this.startMoving,
    required this.direction,
    super.key,
  });

  /// The function to call to get the current direction.
  final MovingDirection? Function() getDirection;

  /// The function to call to start the player moving.
  final void Function(MovingDirection? direction) startMoving;

  /// The direction to call [startMoving] with.
  final MovingDirection direction;

  /// Build the widget.
  @override
  Widget build(final BuildContext context) => IconButton(
    onPressed: () {
      if (getDirection() == direction) {
        startMoving(null);
      } else {
        startMoving(direction);
      }
    },
    icon: Icon(switch (direction) {
      MovingDirection.forwards => Icons.arrow_upward,
      MovingDirection.backwards => Icons.arrow_downward,
      MovingDirection.left => Icons.arrow_left,
      MovingDirection.right => Icons.arrow_right,
    }),
    tooltip: 'Move ${direction.name}',
  );
}
