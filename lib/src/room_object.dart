import 'dart:math';

import 'package:flutter_audio_games/flutter_audio_games.dart';
import 'package:rooms_test/rooms_test.dart';

/// An object in a room.
class RoomObject {
  /// Create an instance.
  const RoomObject({
    required this.name,
    required this.startCoordinates,
    required this.ambiance,
    this.panMultiplier = 0.1,
    this.onApproach,
    this.range = 1,
    this.onLeave,
    this.onActivate,
    this.steps = const [],
    this.repeatSteps = true,
    this.observant = true,
    this.minDistance = 1,
    this.maxDistance = 20,
    this.attenuationModel = 2,
    this.attenuationRolloff = 1.0,
    this.dopplerFactor = 0.0, // Currently handled by `adjustSound`.,
  });

  /// The name of this object.
  final String name;

  /// The starting coordinates of this object.
  final Point<int> startCoordinates;

  /// The ambiance for this sound.
  final Sound ambiance;

  /// The modifier to use to calculate pan.
  ///
  /// The [panMultiplier] will be multiplied with the player's horizontal
  /// distance from this object.
  final double panMultiplier;

  /// The function to call when the player comes into [range] of this object.
  final RoomSurfaceCallback? onApproach;

  /// The range of this object.
  final int range;

  /// The function to call when the player leaves this object's [range].
  final RoomSurfaceCallback? onLeave;

  /// The function to call when the player activates this object.
  final RoomSurfaceCallback? onActivate;

  /// The steps taken by room this object.
  ///
  /// The [steps] list will be looped through. If [repeatSteps] is `true`, then
  /// the [steps] will  be repeated indefinitely.
  final List<RoomObjectStep> steps;

  /// Whether or not to repeat [steps].
  final bool repeatSteps;

  /// Whether this object will notice the player during [steps].
  ///
  /// If [observant] is `false`, then the player will have to approach this
  /// object in order to trigger [onApproach], and walk away from it in order to
  /// trigger [onLeave].
  final bool observant;

  /// The min distance this object can be heard at.
  final int minDistance;

  /// The max distance which this object can be heard at.
  final int maxDistance;

  /// The attenuation model to use.
  final int attenuationModel;

  /// The rolloff factory for source attenuation.
  final double attenuationRolloff;

  /// The doppler factor for this object.
  final double dopplerFactor;
}
