import 'dart:async';
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
    this.tickInterval = const Duration(milliseconds: 200),
    this.pauseDivider = 5,
    this.behindPlaybackSpeed = 0.98,
    this.startCoordinates,
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

  /// How often the room should tick.
  final Duration tickInterval;

  /// The number to divide ambiance volumes by when pausing.
  final double pauseDivider;

  /// The playback speed for objects behind the player.
  final double behindPlaybackSpeed;

  /// jThe starting coordinates for the player.
  ///
  /// If [startCoordinates] ios `null`, then the [room]'s start coordinates will
  /// be used.
  final Point<int>? startCoordinates;

  /// Create state for this widget.
  @override
  RoomWidgetBuilderState createState() => RoomWidgetBuilderState();
}

/// State for [RoomWidgetBuilder].
class RoomWidgetBuilderState extends State<RoomWidgetBuilder> {
  /// Whether this room is paused.
  late bool _paused;

  /// The playback speed to play sounds which are behind the player.
  late final double behindPlaybackSpeed;

  /// |The state of the timed commands.
  late TimedCommandsState _commandsState;

  /// The player's coordinates.
  late Point<int> _coordinates;

  /// Get the coordinates of the player.
  Point<int> get playerCoordinates => _coordinates;

  /// Set player coordinates.
  set playerCoordinates(final Point<int> value) {
    _coordinates = value;
    SoLoud.instance.set3dListenerPosition(
      value.x.toDouble(),
      0,
      value.y.toDouble(),
    );
  }

  /// The direction the player is facing.
  late MovingDirection _direction;

  /// Get the direction the player is moving in.
  ///
  /// If [movingDirection] is `null`, then the player is not moving.
  MovingDirection? get movingDirection {
    if (!_commandsState.commandIsRunning(_movePlayer)) {
      return null;
    }
    return _direction;
  }

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
    _paused = false;
    behindPlaybackSpeed = widget.behindPlaybackSpeed;
    room = widget.room;
    playerCoordinates = widget.startCoordinates ?? room.startingCoordinates;
    _direction = MovingDirection.forwards;
    _ambiances = [];
    _objectCoordinates = [];
    _objectProgresses = [];
    _initObjects();
  }

  /// Initialise [room] objects.
  void _initObjects() {
    for (final list in [_objectCoordinates, _objectProgresses]) {
      list.clear();
    }
    final now = DateTime.now();
    for (final object in room.objects) {
      _objectCoordinates.add(object.startCoordinates);
      _objectProgresses.add(RoomObjectProgress(lastMoved: now, currentStep: 0));
    }
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
    final future = _loadObjectAmbiances();
    return ProtectSounds(
      sounds: [
        for (final surface in room.surfaces) ...surface.footstepSounds ?? [],
        ...room.objects.map((final object) => object.ambiance),
      ],
      child: SimpleFutureBuilder(
        future: future,
        done: (_, _) => LoadSounds(
          sounds: [
            for (final surface in room.surfaces)
              ...surface.footstepSounds ?? [],
          ],
          loading: widget.loading,
          error: widget.error,
          child: Ticking(
            duration: widget.tickInterval,
            onTick: _tickRoom,
            child: TimedCommands(
              builder: (final innerContext, final state) {
                _commandsState = state;
                state.registerCommand(
                  _movePlayer,
                  const Duration(milliseconds: 500),
                );
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

  /// Tick the room.
  void _tickRoom() {
    final now = DateTime.now();
    for (var i = 0; i < room.objects.length; i++) {
      final object = room.objects[i];
      final progress = _objectProgresses[i];
      if (_paused) {
        progress.lastMoved = progress.lastMoved.add(widget.tickInterval);
        continue;
      }
      if (object.steps.isEmpty ||
          (!object.repeatSteps &&
              progress.currentStep >= (object.steps.length - 1))) {
        continue;
      }
      final step = object.steps[progress.currentStep];
      if (now.isAfter(progress.lastMoved + step.delay)) {
        // Update progress.
        progress
          ..lastMoved = now
          ..currentStep = (progress.currentStep + 1) % object.steps.length;
        // Call `onStep`.
        final oldCoordinates = _objectCoordinates[i];
        final wasInRange =
            oldCoordinates.distanceTo(_coordinates) <= object.range;
        step.onStep.call(this, object, oldCoordinates);
        if (object.observant) {
          final newCoordinates = _objectCoordinates[i];
          final inRange =
              newCoordinates.distanceTo(_coordinates) <= object.range;
          if (newCoordinates != oldCoordinates) {
            if (inRange) {
              // The object is now in range.
              if (!wasInRange) {
                // And it wasn't before.
                object.onApproach?.call(this, _coordinates);
              }
            } else if (wasInRange) {
              // The object is not in range, but was before it moved.
              object.onLeave?.call(this, _coordinates);
            }
          }
        }
      }
    }
  }

  /// Activate any nearby objects.
  void activateNearbyObject() {
    for (var i = 0; i < room.objects.length; i++) {
      final object = room.objects[i];
      final objectCoordinates = _objectCoordinates[i];
      if (_coordinates.distanceTo(objectCoordinates) <= object.range) {
        final onActivate = object.onActivate;
        if (onActivate != null) {
          onActivate.call(this, _coordinates);
          break;
        }
      }
    }
  }

  /// Start the player moving.
  void startPlayer(final MovingDirection direction) {
    _direction = direction;
    _commandsState.startCommand(_movePlayer);
  }

  /// Stop the player moving.
  void stopPlayer() {
    _commandsState.stopCommand(_movePlayer);
  }

  /// Set the volume and pan of all object [_ambiances].
  void adjustObjectSounds({required final Duration fade}) {
    for (var i = 0; i < room.objects.length; i++) {
      final ambiance = _ambiances[i];
      final objectCoordinates = _objectCoordinates[i];
      adjustSound(ambiance, objectCoordinates, fade);
    }
  }

  /// Adjust the playback speed of [ambiance] according to [objectCoordinates].
  void adjustSound(
    final SoundHandle ambiance,
    final Point<int> objectCoordinates,
    final Duration fade,
  ) {
    ambiance.relativePlaySpeed.fade(
      (objectCoordinates.y < _coordinates.y) ? widget.behindPlaybackSpeed : 1.0,
      fade,
    );
  }

  /// Load object ambiances.
  Future<void> _loadObjectAmbiances() async {
    for (final ambiance in _ambiances) {
      unawaited(ambiance.stop());
    }
    _ambiances.clear();
    for (final object in room.objects) {
      final ambiance = await context.playSound(
        object.ambiance.copyWith(
          volume: 0.0,
          position: object.startCoordinates.soundPosition3d,
        ),
      );
      _ambiances.add(ambiance);
      ambiance.volume.fade(object.ambiance.volume, room.fadeIn);
      // Setting the listener position again seems to fix sound positions.
      adjustSound(ambiance, object.startCoordinates, Duration.zero);
    }
    Timer(
      const Duration(milliseconds: 20),
      () => playerCoordinates = _coordinates,
    );
  }

  /// Move the player.
  void _movePlayer() {
    if (_paused) {
      return;
    }
    final c = switch (_direction) {
      MovingDirection.forwards => _coordinates.north,
      MovingDirection.backwards => _coordinates.south,
      MovingDirection.left => _coordinates.west,
      MovingDirection.right => _coordinates.east,
    };
    final oldSurface = getSurfaceAt(_coordinates);
    final newSurface = getSurfaceAt(c);
    if (newSurface == null) {
      stopPlayer();
      oldSurface?.onWall?.call(this, c);
      return;
    }
    if (newSurface != oldSurface) {
      oldSurface?.onExit?.call(this, _coordinates);
      newSurface.onEnter?.call(this, c);
      _commandsState.setCommandInterval(_movePlayer, newSurface.movementSpeed);
    }
    final inRange = <RoomObject>[];
    final outOfRange = <RoomObject>[];
    for (var i = 0; i < room.objects.length; i++) {
      final object = room.objects[i];
      final objectCoordinates = _objectCoordinates[i];
      if (objectCoordinates.distanceTo(_coordinates) <= object.range) {
        inRange.add(object);
      } else {
        outOfRange.add(object);
      }
    }
    playerCoordinates = c;
    newSurface.onMove?.call(this, c);
    final footstepSounds = newSurface.footstepSounds;
    if (footstepSounds != null) {
      context.playRandomSound(footstepSounds);
    }
    adjustObjectSounds(fade: newSurface.movementSpeed);
    for (var i = 0; i < room.objects.length; i++) {
      final object = room.objects[i];
      final objectCoordinates = _objectCoordinates[i];
      if (_coordinates.distanceTo(objectCoordinates) <= object.range) {
        // Object is now in range.
        if (outOfRange.contains(object)) {
          // And it wasn't before.
          object.onApproach?.call(this, _coordinates);
        }
      } else if (inRange.contains(object)) {
        // The object is not in range, but was before the last move.
        object.onLeave?.call(this, _coordinates);
      }
    }
  }

  /// Move [object] to [newCoordinates].
  void moveObject(final RoomObject object, final Point<int> newCoordinates) {
    final index = room.objects.indexOf(object);
    if (index == -1) {
      throw StateError('Cannot find ${object.name} in ${room.title}.');
    }
    _objectCoordinates[index] = newCoordinates;
    _ambiances[index].setSourcePosition(
      newCoordinates.x.toDouble(),
      0,
      newCoordinates.y.toDouble(),
    );
    adjustSound(
      _ambiances[index],
      newCoordinates,
      getSurfaceAt(newCoordinates)?.movementSpeed ?? Duration.zero,
    );
  }

  /// Pause the game.
  void pause() {
    _paused = true;
    stopPlayer();
    for (var i = 0; i < room.objects.length; i++) {
      final object = room.objects[i];
      final ambiance = _ambiances[i];
      ambiance.volume.fade(
        object.ambiance.volume / widget.pauseDivider,
        room.fadeOut,
      );
    }
  }

  /// Unpause the game.
  void unpause() {
    _paused = false;
    for (var i = 0; i < room.objects.length; i++) {
      final object = room.objects[i];
      final ambiance = _ambiances[i];
      ambiance.volume.fade(object.ambiance.volume, room.fadeIn);
    }
  }

  /// Get the surface which has been laid at [coordinates].
  RoomSurface? getSurfaceAt(final Point<int> coordinates) {
    for (final surface in room.surfaces) {
      if (surface.isCovering(coordinates)) {
        return surface;
      }
    }
    return null;
  }
}
