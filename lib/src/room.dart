import 'dart:math';

import 'package:flutter_audio_games/flutter_audio_games.dart';
import 'package:rooms_test/rooms_test.dart';

/// A single room.
class Room {
  /// Create an instance.
  const Room({
    required this.title,
    required this.footstepSoundNames,
    this.width = 10,
    this.depth = 10,
    this.startingCoordinates = const Point(0, 0),
    this.objects = const [],
    this.movementSpeed = const Duration(milliseconds: 400),
    this.behindPlaybackRate = 0.98,
    this.fadeIn = const Duration(seconds: 3),
    this.fadeOut = const Duration(seconds: 4),
  });

  /// The title of this room.
  final String title;

  /// The width of this room.
  final int width;

  /// The depth of this room.
  final int depth;

  /// The starting coordinates for this room.
  final Point<int> startingCoordinates;

  /// The names of the footstep sounds for this room.
  final List<String> footstepSoundNames;

  /// The footstep sounds for this room.
  List<Sound> get footstepSounds => footstepSoundNames
      .map((final name) => name.asSound(destroy: true))
      .toList();

  /// The objects in this room.
  final List<RoomObject> objects;

  /// How fast the player can move in this room.
  final Duration movementSpeed;

  /// The playback rate for objects behind the player.
  final double behindPlaybackRate;

  /// The fade in value for sounds in this room.
  final Duration fadeIn;

  /// The fade out value for sounds in this room.
  final Duration fadeOut;
}
