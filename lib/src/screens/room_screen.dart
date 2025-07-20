import 'dart:math';

import 'package:backstreets_widgets/extensions.dart';
import 'package:backstreets_widgets/screens.dart';
import 'package:backstreets_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_games/flutter_audio_games.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:rooms_test/rooms_test.dart';

/// A screen which renders a [room].
class RoomScreen extends StatefulWidget {
  /// Create an instance.
  const RoomScreen({required this.room, super.key});

  /// The room to display.
  final Room room;

  /// Create state for this widget.
  @override
  RoomScreenState createState() => RoomScreenState();
}

/// State for [RoomScreen].
class RoomScreenState extends State<RoomScreen> {
  /// |The state of the timed commands.
  late TimedCommandsState _commandsState;

  /// The player's coordinates.
  late Point<int> _coordinates;

  /// The direction the player is facing.
  late MovingDirection _direction;

  /// The room to work with.
  late final Room room;

  /// The objects in this room.
  late final List<Point<int>> _roomObjectCoordinates;

  /// The ambiances to work on.
  late final List<SoundHandle> _ambiances;

  /// Initialise state.
  @override
  void initState() {
    super.initState();
    room = widget.room;
    _roomObjectCoordinates = room.objects
        .map((final object) => object.startCoordinates)
        .toList();
    _coordinates = room.startingCoordinates;
    _direction = MovingDirection.forwards;
    _ambiances = [];
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
    const loading = LoadingScreen.new;
    const error = ErrorScreen.withPositional;
    return ProtectSounds(
      sounds: [
        ...room.footstepSounds,
        ...room.objects.map((final object) => object.ambiance),
      ],
      child: SimpleFutureBuilder(
        future: _loadObjectAmbiances(),
        done: (_, _) => LoadSounds(
          sounds: room.footstepSounds,
          loading: loading,
          error: error,
          child: SimpleScaffold(
            title: room.title,
            body: TimedCommands(
              builder: (final context, final state) {
                _commandsState = state;
                state.registerCommand(_movePlayer, room.movementSpeed);
                return GameShortcuts(
                  shortcuts: [
                    GameShortcut(
                      title: 'Announce coordinates',
                      shortcut: GameShortcutsShortcut.keyC,
                      onStart: (final innerContext) => context.announce(
                        '${_coordinates.x}, ${_coordinates.y}',
                      ),
                    ),
                    GameShortcut(
                      title: 'Move north',
                      shortcut: GameShortcutsShortcut.arrowUp,
                      onStart: (final innerContext) {
                        _direction = MovingDirection.forwards;
                        _commandsState.startCommand(_movePlayer);
                      },
                      onStop: stopPlayer,
                    ),
                    GameShortcut(
                      title: 'Move south',
                      shortcut: GameShortcutsShortcut.arrowDown,
                      onStart: (final innerContext) {
                        _direction = MovingDirection.backwards;
                        _commandsState.startCommand(_movePlayer);
                      },
                      onStop: stopPlayer,
                    ),
                    GameShortcut(
                      title: 'Move east',
                      shortcut: GameShortcutsShortcut.arrowRight,
                      onStart: (final innerContext) {
                        _direction = MovingDirection.right;
                        _commandsState.startCommand(_movePlayer);
                      },
                      onStop: stopPlayer,
                    ),
                    GameShortcut(
                      title: 'Move west',
                      shortcut: GameShortcutsShortcut.arrowLeft,
                      onStart: (final innerContext) {
                        _direction = MovingDirection.left;
                        _commandsState.startCommand(_movePlayer);
                      },
                      onStop: stopPlayer,
                    ),
                    GameShortcut(
                      title: 'Activate nearby object',
                      shortcut: GameShortcutsShortcut.enter,
                      onStart: (final innerContext) {
                        for (var i = 0; i < room.objects.length; i++) {
                          final object = room.objects[i];
                          final objectCoordinates = _roomObjectCoordinates[i];
                          if (_coordinates.distanceTo(objectCoordinates) <=
                              object.range) {
                            object.onActivate?.call();
                          }
                        }
                      },
                    ),
                    GameShortcut(
                      title: 'Move an object left',
                      shortcut: GameShortcutsShortcut.bracketLeft,
                      onStart: (final innerContext) {
                        final object = room.objects.first;
                        final oldCoordinates = _roomObjectCoordinates.first;
                        moveObject(object, oldCoordinates.west);
                      },
                    ),
                    GameShortcut(
                      title: 'Move an object right',
                      shortcut: GameShortcutsShortcut.bracketRight,
                      onStart: (final innerContext) {
                        final object = room.objects.first;
                        final oldCoordinates = _roomObjectCoordinates.first;
                        moveObject(object, oldCoordinates.east);
                      },
                    ),
                  ],
                  child: const Text('Keyboard'),
                );
              },
            ),
          ),
        ),
        loading: loading,
        error: error,
      ),
    );
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
      final objectCoordinates = _roomObjectCoordinates[i];
      adjustSound(object, ambiance, objectCoordinates, fade);
    }
  }

  /// Adjust the [ambiance] of [object].
  void adjustSound(
    final RoomObject object,
    final SoundHandle ambiance,
    final Point<int> objectCoordinates,
    final Duration fade, {
    final Duration? panFade,
    final Duration? rateFade,
  }) {
    var muted = false;
    // First, let's calculate relative pan.
    final difference =
        max(_coordinates.x, objectCoordinates.x) -
        min(_coordinates.x, objectCoordinates.x);
    final pan = object.panMultiplier * difference;
    if (pan > 1.0) {
      ambiance.volume.fade(0, fade);
      muted = true;
    } else {
      ambiance.pan.fade(switch (_coordinates.x.compareTo(objectCoordinates.x)) {
        -1 => pan, // Object is to the right.
        1 => -pan, // Object is to the left.
        _ => 0.0, // Object is directly in front or behind.
      }, panFade ?? fade);
    }
    if (muted) {
      return; // Don't change volume.
    }
    // Let's calculate the volume and pitch difference.
    if (_coordinates.y == objectCoordinates.y) {
      ambiance
        ..volume.fade(object.ambiance.volume, fade)
        ..relativePlaySpeed.fade(1.0, rateFade ?? fade);
    } else {
      if (objectCoordinates.y < _coordinates.y) {
        // The object is behind us. Let's decrease the pitch.
        ambiance.relativePlaySpeed.fade(room.behindPlaybackRate, fade);
      }
      final difference =
          max(_coordinates.y, objectCoordinates.y) -
          min(_coordinates.y, objectCoordinates.y);
      final volume =
          object.ambiance.volume - (difference * object.distanceAttenuation);
      if (volume < 0.0) {
        ambiance.volume.fade(0, fade);
      } else {
        ambiance.volume.fade(volume, fade);
      }
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
        rateFade: Duration.zero,
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
    _roomObjectCoordinates[index] = newCoordinates;
    adjustSound(
      object,
      _ambiances[index],
      newCoordinates,
      speed ?? room.movementSpeed,
    );
  }
}
