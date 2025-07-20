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
  late Point<int> coordinates;

  /// The direction the player is facing.
  late MovingDirection direction;

  /// The room to work with.
  late final Room room;

  /// The ambiances to work on.
  late final List<SoundHandle> ambiances;

  /// Initialise state.
  @override
  void initState() {
    super.initState();
    room = widget.room;
    coordinates = room.startingCoordinates;
    direction = MovingDirection.forwards;
    ambiances = [];
  }

  /// Dispose of the widget.
  @override
  void dispose() {
    super.dispose();
    for (final ambiance in ambiances) {
      ambiance.stop();
    }
    ambiances.clear();
  }

  /// Build a widget.
  @override
  Widget build(final BuildContext context) {
    for (final ambiance in ambiances) {
      ambiance.stop();
    }
    ambiances.clear();
    const loading = LoadingScreen.new;
    const error = ErrorScreen.withPositional;
    return ProtectSounds(
      sounds: [
        ...room.footstepSounds,
        ...room.objects.map((final object) => object.ambiance),
      ],
      child: SimpleFutureBuilder(
        future: loadObjectAmbiances(),
        done: (_, _) => LoadSounds(
          sounds: room.footstepSounds,
          loading: loading,
          error: error,
          child: SimpleScaffold(
            title: room.title,
            body: TimedCommands(
              builder: (final context, final state) {
                _commandsState = state;
                state.registerCommand(movePlayer, room.movementSpeed);
                return GameShortcuts(
                  shortcuts: [
                    GameShortcut(
                      title: 'Announce coordinates',
                      shortcut: GameShortcutsShortcut.keyC,
                      onStart: (final innerContext) => context.announce(
                        '${coordinates.x}, ${coordinates.y}',
                      ),
                    ),
                    GameShortcut(
                      title: 'Move north',
                      shortcut: GameShortcutsShortcut.arrowUp,
                      onStart: (final innerContext) {
                        direction = MovingDirection.forwards;
                        _commandsState.startCommand(movePlayer);
                      },
                      onStop: stopPlayer,
                    ),
                    GameShortcut(
                      title: 'Move south',
                      shortcut: GameShortcutsShortcut.arrowDown,
                      onStart: (final innerContext) {
                        direction = MovingDirection.backwards;
                        _commandsState.startCommand(movePlayer);
                      },
                      onStop: stopPlayer,
                    ),
                    GameShortcut(
                      title: 'Move east',
                      shortcut: GameShortcutsShortcut.arrowRight,
                      onStart: (final innerContext) {
                        direction = MovingDirection.right;
                        _commandsState.startCommand(movePlayer);
                      },
                      onStop: stopPlayer,
                    ),
                    GameShortcut(
                      title: 'Move west',
                      shortcut: GameShortcutsShortcut.arrowLeft,
                      onStart: (final innerContext) {
                        direction = MovingDirection.left;
                        _commandsState.startCommand(movePlayer);
                      },
                      onStop: stopPlayer,
                    ),
                    GameShortcut(
                      title: 'Activate nearby object',
                      shortcut: GameShortcutsShortcut.enter,
                      onStart: (final innerContext) {
                        for (final object in room.objects) {
                          if (coordinates.distanceTo(object.coordinates) <=
                              object.range) {
                            object.onActivate?.call();
                          }
                        }
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
    _commandsState.stopCommand(movePlayer);
  }

  /// Set the volume and pan of all object [ambiances].
  void adjustObjectSounds({required final Duration fade}) {
    for (var i = 0; i < room.objects.length; i++) {
      final object = room.objects[i];
      final ambiance = ambiances[i];
      adjustSound(object, ambiance, fade);
    }
  }

  /// Adjust the [ambiance] of [object].
  void adjustSound(
    final RoomObject object,
    final SoundHandle ambiance,
    final Duration fade,
  ) {
    // First let's calculate the volume and pitch difference.
    if (coordinates.y == object.coordinates.y) {
      ambiance
        ..volume.fade(object.ambiance.volume, fade)
        ..relativePlaySpeed.fade(1.0, fade);
    } else {
      if (object.coordinates.y < coordinates.y) {
        // The object is behind us. Let's decrease the pitch.
        ambiance.relativePlaySpeed.fade(room.behindPlaybackRate, fade);
      }
      final difference =
          max(coordinates.y, object.coordinates.y) -
          min(coordinates.y, object.coordinates.y);
      final volume =
          object.ambiance.volume - (difference * object.distanceAttenuation);
      if (volume < 0.0) {
        ambiance.volume.fade(0, fade);
      } else {
        ambiance.volume.fade(volume, fade);
      }
    }
    // Let's calculate relative pan.
    final difference =
        max(coordinates.x, object.coordinates.x) -
        min(coordinates.x, object.coordinates.x);
    final pan = object.panMultiplier * difference;
    if (pan > 1.0) {
      ambiance.volume.fade(0, fade);
    } else {
      ambiance.pan.fade(switch (coordinates.x.compareTo(object.coordinates.x)) {
        -1 => pan, // Object is to the right.
        1 => -pan, // Object is to the left.
        _ => 0.0, // Object is directly in front or behind.
      }, fade);
    }
  }

  /// Load object ambiances.
  Future<void> loadObjectAmbiances() async {
    for (final object in room.objects) {
      ambiances.add(await context.playSound(object.ambiance));
    }
    adjustObjectSounds(fade: Duration.zero);
  }

  /// Move the player.
  void movePlayer() {
    final c = switch (direction) {
      MovingDirection.forwards => coordinates.north,
      MovingDirection.backwards => coordinates.south,
      MovingDirection.left => coordinates.west,
      MovingDirection.right => coordinates.east,
    };
    if (c.x < 0 || c.y < 0 || c.x > room.width || c.y > room.depth) {
      return;
    }
    coordinates = c;
    context.playRandomSound(room.footstepSounds);
    adjustObjectSounds(fade: room.movementSpeed);
  }
}
