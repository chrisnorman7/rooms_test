import 'dart:math';

import 'package:rooms_test/rooms_test.dart';

/// A single room.
class Room {
  /// Create an instance.
  const Room({
    required this.title,
    required this.surfaces,
    this.startingCoordinates = const Point(0, 0),
    this.objects = const [],
    this.movementSpeed = const Duration(milliseconds: 400),
    this.behindPlaybackSpeed = 0.98,
    this.fadeIn = const Duration(seconds: 3),
    this.fadeOut = const Duration(seconds: 4),
  }) : assert(
         surfaces.length > 0,
         'At least 1 surface must be present in each room.',
       );

  /// The title of this room.
  final String title;

  /// The surfaces which have been laid in this room.
  final List<RoomSurface> surfaces;

  /// The starting coordinates for this room.
  final Point<int> startingCoordinates;

  /// The objects in this room.
  final List<RoomObject> objects;

  /// How fast the player can move in this room.
  final Duration movementSpeed;

  /// The playback speed for objects behind the player.
  final double behindPlaybackSpeed;

  /// The fade in value for sounds in this room.
  final Duration fadeIn;

  /// The fade out value for sounds in this room.
  final Duration fadeOut;
}
