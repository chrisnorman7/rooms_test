import 'dart:math';

import 'package:backstreets_widgets/extensions.dart';
import 'package:backstreets_widgets/screens.dart';
import 'package:backstreets_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_games/flutter_audio_games.dart';
import 'package:rooms_test/rooms_test.dart';

/// The type for a set room function.
typedef SetRoom = void Function(Room room, {Point<int>? coordinates});

/// The default screen to use for rooms.
///
/// This screen uses standard wasd keys for movement, the enter and space keys
/// for activating objects, and shift+/ for help.
///
/// The player can use the c key to announce the current coordinates.
class DefaultRoomScreen extends StatefulWidget {
  /// Create an instance.
  const DefaultRoomScreen({
    required this.getRoom,
    this.startCoordinates,
    super.key,
  });

  /// The room to use.
  final Room Function(SetRoom setRoom) getRoom;

  /// The coordinates where the player should start.
  final Point<int>? startCoordinates;

  @override
  State<DefaultRoomScreen> createState() => _DefaultRoomScreenState();
}

/// State for [DefaultRoomScreen].
///
/// To update the current room, use the [setRoom] method.
class _DefaultRoomScreenState extends State<DefaultRoomScreen> {
  /// The current room.
  late Room _room;

  /// The player's starting coordinates.
  late Point<int> _coordinates;

  /// Initialise state.
  @override
  void initState() {
    super.initState();
    _room = widget.getRoom(setRoom);
    _coordinates = widget.startCoordinates ?? _room.startingCoordinates;
  }

  /// Build the widget.
  @override
  Widget build(final BuildContext context) => RoomWidgetBuilder(
    room: _room,
    builder: (final context, final state) => SimpleScaffold(
      title: _room.title,
      body: GameShortcuts(
        shortcuts: [
          GameShortcut(
            title: 'Announce coordinates',
            shortcut: GameShortcutsShortcut.keyC,
            onStart: (final innerContext) => context.announce(
              // ignore: lines_longer_than_80_chars
              '${state.playerCoordinates.x}, ${state.playerCoordinates.y}',
            ),
          ),
          GameShortcut(
            title: 'Move north',
            shortcut: GameShortcutsShortcut.keyW,
            onStart: (final innerContext) {
              state.startPlayer(MovingDirection.forwards);
            },
            onStop: (final innerContext) => state.stopPlayer(),
          ),
          GameShortcut(
            title: 'Move south',
            shortcut: GameShortcutsShortcut.keyS,
            onStart: (final innerContext) {
              state.startPlayer(MovingDirection.backwards);
            },
            onStop: (final innerContext) => state.stopPlayer(),
          ),
          GameShortcut(
            title: 'Move east',
            shortcut: GameShortcutsShortcut.keyD,
            onStart: (final innerContext) {
              state.startPlayer(MovingDirection.right);
            },
            onStop: (final innerContext) => state.stopPlayer(),
          ),
          GameShortcut(
            title: 'Move west',
            shortcut: GameShortcutsShortcut.keyA,
            onStart: (final innerContext) {
              state.startPlayer(MovingDirection.left);
            },
            onStop: (final innerContext) => state.stopPlayer(),
          ),
          GameShortcut(
            title: 'Activate nearby object',
            shortcut: GameShortcutsShortcut.enter,
            onStart: (final innerContext) {
              state.activateNearbyObject();
            },
          ),
          GameShortcut(
            title: 'Show menu',
            shortcut: GameShortcutsShortcut.escape,
            onStart: (final innerContext) => state.runPaused(
              () => innerContext.pushWidgetBuilder(
                (_) => SimpleScaffold(
                  title: 'Pause Menu',
                  body: ListView(
                    shrinkWrap: true,
                    children: [
                      CopyListTile(
                        autofocus: true,
                        title: 'Coordinates',
                        subtitle:
                            // ignore: lines_longer_than_80_chars
                            '${state.playerCoordinates.x}, ${state.playerCoordinates.y}',
                      ),
                      ListTile(
                        title: const Text('Return to game'),
                        onTap: innerContext.pop,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        child: const Text('Keyboard'),
      ),
    ),
    loading: LoadingScreen.new,
    error: ErrorScreen.withPositional,
    startCoordinates: _coordinates,
    key: ValueKey(_room),
  );

  /// Set the current room.
  void setRoom(final Room room, {final Point<int>? coordinates}) {
    setState(() {
      _room = room;
      _coordinates = coordinates ?? room.startingCoordinates;
    });
  }
}
