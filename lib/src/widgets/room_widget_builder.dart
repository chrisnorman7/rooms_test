import 'dart:math';

import 'package:backstreets_widgets/typedefs.dart';
import 'package:backstreets_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_games/flutter_audio_games.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:rooms_test/rooms_test.dart';
import 'package:time/time.dart';

/// A screen which renders a [room].
class RoomWidgetBuilder extends StatefulWidget {
  /// Create an instance.
  const RoomWidgetBuilder({
    required this.room,
    required this.loading,
    required this.error,
    required this.builder,
    super.key,
  });

  /// The room to display.
  final Room room;

  /// The function to call to show a loading widget.
  final Widget Function() loading;

  /// The function to call to show an error widget.
  final ErrorWidgetCallback error;

  /// The function which is used to build the widget.
  final Widget Function(BuildContext context, RoomWidgetBuilderState state)
  builder;

  /// Create state for this widget.
  @override
  RoomWidgetBuilderState createState() => RoomWidgetBuilderState();
}

/// State for [RoomWidgetBuilder].
class RoomWidgetBuilderState extends State<RoomWidgetBuilder> {
  /// |The state of the timed commands.
  late TimedCommandsState _commandsState;

  /// The player's coordinates.
  late Point<int> _coordinates;

  /// Get the coordinates of the player.
  Point<int> get playerCoordinates => _coordinates;

  /// The direction the player is facing.
  late MovingDirection _direction;

  /// The room to work with.
  late final Room room;

  /// The objects in this room.
  late final List<Point<int>> _objectCoordinates;

  /// The ambiances to work on.
  late final List<SoundHandle> _ambiances;

  /// The progress of each object.
  late final List<RoomObjectProgress> _objectProgresses;

  /// Initialise state.
  @override
  void initState() {
    super.initState();
    room = widget.room;
    _objectCoordinates = room.objects
        .map((final object) => object.startCoordinates)
        .toList();
    _coordinates = room.startingCoordinates;
    _direction = MovingDirection.forwards;
    _ambiances = [];
    final now = DateTime.now();
    _objectProgresses = room.objects
        .map(
          (final object) => RoomObjectProgress(lastMoved: now, currentStep: 0),
        )
        .toList();
  }

  /// Dispose of the widget.
  @override
  void dispose() {
    super.dispose();
    for (final ambiance in _ambiances) {
      ambiance.stop(fadeOutTime: room.fadeOut);
    }
    _ambiances.clear();
  }

  /// Build a widget.
  @override
  Widget build(final BuildContext context) {
    for (final ambiance in _ambiances) {
      ambiance.stop();
    }
    _ambiances.clear();
    return ProtectSounds(
      sounds: [
        ...room.footstepSounds,
        ...room.objects.map((final object) => object.ambiance),
      ],
      child: SimpleFutureBuilder(
        future: _loadObjectAmbiances(),
        done: (_, _) => LoadSounds(
          sounds: room.footstepSounds,
          loading: widget.loading,
          error: widget.error,
          child: Ticking(
            duration: 0.2.seconds,
            onTick: () {
              final now = DateTime.now();
              for (var i = 0; i < room.objects.length; i++) {
                final object = room.objects[i];
                final progress = _objectProgresses[i];
                if (object.steps.isEmpty ||
                    (!object.repeatSteps &&
                        progress.currentStep == (object.steps.length - 1))) {
                  continue;
                }
                final step = object.steps[progress.currentStep];
                if (now.isAfter(progress.lastMoved + step.delay)) {
                  // Update progress.
                  progress
                    ..lastMoved = now
                    ..currentStep =
                        (progress.currentStep + 1) % object.steps.length;
                  // Call `onStep`.
                  step.onStep.call(this, object, _objectCoordinates[i]);
                }
              }
            },
            child: TimedCommands(
              builder: (final innerContext, final state) {
                _commandsState = state;
                state.registerCommand(_movePlayer, room.movementSpeed);
                return widget.builder(innerContext, this);
              },
            ),
          ),
        ),
        loading: widget.loading,
        error: widget.error,
      ),
    );
  }

  /// Activate any nearby objects.
  void activateNearbyObject() {
    for (var i = 0; i < room.objects.length; i++) {
      final object = room.objects[i];
      final objectCoordinates = _objectCoordinates[i];
      if (_coordinates.distanceTo(objectCoordinates) <= object.range) {
        object.onActivate?.call();
      }
    }
  }

  /// Start the player moving.
  void startPlayer(final MovingDirection direction) {
    _direction = direction;
    _commandsState.startCommand(_movePlayer);
  }

  /// Stop the player moving.
  void stopPlayer(final BuildContext innerContext) {
    _commandsState.stopCommand(_movePlayer);
  }

  /// Set the volume and pan of all object [_ambiances].
  void adjustObjectSounds({required final Duration fade}) {
    for (var i = 0; i < room.objects.length; i++) {
      final object = room.objects[i];
      final ambiance = _ambiances[i];
      final objectCoordinates = _objectCoordinates[i];
      adjustSound(object, ambiance, objectCoordinates, fade);
    }
  }

  /// Get sound settings for a sound at [coordinates].
  SoundSettings getSoundSettings({
    required final Point<int> coordinates,
    required final double fullVolume,
    required final double panMultiplier,
    required final double distanceAttenuation,
  }) {
    // First, let's calculate relative pan.
    final difference =
        max(_coordinates.x, coordinates.x) - min(_coordinates.x, coordinates.x);
    final halfPan = panMultiplier * difference;
    if (halfPan > 1.0) {
      return const SoundSettings(volume: 0.0, pan: 0.0, playbackSpeed: 1.0);
    }
    final pan = switch (_coordinates.x.compareTo(coordinates.x)) {
      -1 => halfPan, // Object is to the right.
      1 => -halfPan, // Object is to the left.
      _ => 0.0, // Object is directly in front or behind.
    };
    // Let's calculate the volume and pitch difference.
    final double volume;
    final double playbackSpeed;
    if (_coordinates.y == coordinates.y) {
      volume = fullVolume;
      playbackSpeed = 1.0;
    } else {
      if (coordinates.y < _coordinates.y) {
        // The object is behind us. Let's decrease the pitch.
        playbackSpeed = room.behindPlaybackSpeed;
      } else {
        playbackSpeed = 1.0;
      }
      final difference =
          max(_coordinates.y, coordinates.y) -
          min(_coordinates.y, coordinates.y);
      volume = fullVolume - (difference * distanceAttenuation);
    }
    return SoundSettings(
      volume: max(0.0, volume),
      pan: pan,
      playbackSpeed: playbackSpeed,
    );
  }

  /// Adjust the [ambiance] of [object].
  void adjustSound(
    final RoomObject object,
    final SoundHandle ambiance,
    final Point<int> objectCoordinates,
    final Duration fade, {
    final Duration? panFade,
    final Duration? speedFade,
  }) {
    final soundSettings = getSoundSettings(
      coordinates: objectCoordinates,
      fullVolume: object.ambiance.volume,
      panMultiplier: object.panMultiplier,
      distanceAttenuation: object.distanceAttenuation,
    );
    if (soundSettings.isMuted) {
      ambiance.volume.fade(0.0, fade);
    } else {
      ambiance
        ..volume.fade(soundSettings.volume, fade)
        ..pan.fade(soundSettings.pan, panFade ?? fade)
        ..relativePlaySpeed.fade(
          soundSettings.playbackSpeed,
          speedFade ?? fade,
        );
    }
  }

  /// Load object ambiances.
  Future<void> _loadObjectAmbiances() async {
    for (final object in room.objects) {
      final ambiance = await context.playSound(
        object.ambiance.copyWith(volume: 0.0),
      );
      _ambiances.add(ambiance);
      adjustSound(
        object,
        ambiance,
        object.startCoordinates,
        room.fadeIn,
        panFade: Duration.zero,
        speedFade: Duration.zero,
      );
    }
  }

  /// Move the player.
  void _movePlayer() {
    final c = switch (_direction) {
      MovingDirection.forwards => _coordinates.north,
      MovingDirection.backwards => _coordinates.south,
      MovingDirection.left => _coordinates.west,
      MovingDirection.right => _coordinates.east,
    };
    if (c.x < 0 || c.y < 0 || c.x > room.width || c.y > room.depth) {
      return;
    }
    _coordinates = c;
    context.playRandomSound(room.footstepSounds);
    adjustObjectSounds(fade: room.movementSpeed);
  }

  /// Move [object] to [newCoordinates].
  ///
  /// If [speed] is `null`, then `room.movementSpeed` will be used.
  void moveObject(
    final RoomObject object,
    final Point<int> newCoordinates, {
    final Duration? speed,
  }) {
    final index = room.objects.indexOf(object);
    if (index == -1) {
      throw StateError('Cannot find ${object.name} in ${room.title}.');
    }
    _objectCoordinates[index] = newCoordinates;
    adjustSound(
      object,
      _ambiances[index],
      newCoordinates,
      speed ?? room.movementSpeed,
    );
  }
}
