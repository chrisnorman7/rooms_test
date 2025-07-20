import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_audio_games/flutter_audio_games.dart';

/// An object in a room.
class RoomObject {
  /// Create an instance.
  const RoomObject({
    required this.name,
    required this.coordinates,
    required this.ambiance,
    this.distanceAttenuation = 0.1,
    this.panMultiplier = 0.1,
    this.onApproach,
    this.range = 1,
    this.onLeave,
    this.onActivate,
  });

  /// The name of this object.
  final String name;

  /// The coordinates of this object.
  final Point<int> coordinates;

  /// The ambiance for this sound.
  final Sound ambiance;

  /// The multiplier to use for distance attenuation.
  final double distanceAttenuation;

  /// The modifier to use to calculate pan.
  ///
  /// The [panMultiplier] will be multiplied with the player's horizontal
  /// distance from this object.
  final double panMultiplier;

  /// The function to call when the player comes into [range] of this object.
  final VoidCallback? onApproach;

  /// The range of this object.
  final int range;

  /// The function to call when the player leaves this object's [range].
  final VoidCallback? onLeave;

  /// The function to call when the player activates this object.
  final VoidCallback? onActivate;
}
