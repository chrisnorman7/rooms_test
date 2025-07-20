import 'dart:math';

import 'package:backstreets_widgets/extensions.dart';
import 'package:backstreets_widgets/screens.dart';
import 'package:backstreets_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_games/flutter_audio_games.dart';
import 'package:rooms_test/rooms_test.dart';
import 'package:time/time.dart';

/// The screen for the first room.
class StartRoomScreen extends StatelessWidget {
  /// Create an instance.
  const StartRoomScreen({super.key});

  /// Build the widget.
  @override
  Widget build(final BuildContext context) {
    final ambiances = Assets.sounds.ambiances;
    const radioStartCoordinates = Point(5, 9);
    final footsteps = Assets.sounds.footsteps;
    final surface1 = RoomSurface(
      start: const Point(0, 0),
      width: 10,
      depth: 10,
      footstepSoundNames: footsteps.bootsLinoleum.values,
      onEnter: (final state, final coordinates) =>
          context.announce('You enter the main room.'),
      onWall: (final state, final coordinates) => onWall(context),
    );
    final room = Room(
      title: 'Living Room',
      surfaces: [
        surface1,
        RoomSurface(
          start: surface1.east,
          width: surface1.width,
          depth: surface1.depth,
          footstepSoundNames: footsteps.metalStep.values,
          onEnter: (final state, final coordinates) =>
              context.announce('You enter a metal place.'),
          onExit: (final state, final coordinates) => context.playSound(
            Assets.sounds.interface.machineSwitch.asSound(destroy: true),
          ),
          onWall: (final state, final coordinates) => onWall(context),
          movementSpeed: 1.seconds,
        ),
      ],
      startingCoordinates: const Point(5, 5),
      objects: [
        RoomObject(
          name: 'Pump',
          startCoordinates: const Point(0, 0),
          ambiance: ambiances.pump.asSound(destroy: false, looping: true),
        ),
        RoomObject(
          name: 'Metal thing',
          startCoordinates: const Point(5, 5),
          ambiance: ambiances.metal.asSound(destroy: false, looping: true),
          onActivate: () => context.playSound(
            Assets.sounds.interface.machineSwitch.asSound(destroy: true),
          ),
        ),
        RoomObject(
          name: 'Radio',
          startCoordinates: radioStartCoordinates,
          ambiance: ambiances.radio.asSound(destroy: false, looping: true),
          steps: [
            ...[for (var i = radioStartCoordinates.y; i > 0; i--) i].map(
              (final i) => RoomObjectStep(
                onStep: (final state, final object, final coordinates) {
                  final surface = state.getSurfaceAt(coordinates);
                  final destination = coordinates.south;
                  if (surface != null) {
                    final footstepSound = surface.footstepSounds
                        .randomElement();
                    final soundSettings = state.getSoundSettings(
                      coordinates: destination,
                      fullVolume: footstepSound.volume,
                      panMultiplier: object.panMultiplier,
                      maxDistance: object.maxDistance,
                    );
                    context.playSound(
                      footstepSound.copyWith(
                        position: SoundPositionPanned(soundSettings.pan),
                        relativePlaySpeed: soundSettings.playbackSpeed,
                        volume: soundSettings.volume,
                      ),
                    );
                  }
                  state.moveObject(object, destination);
                },
              ),
            ),
            RoomObjectStep(
              onStep: (final state, final object, final coordinates) {
                context.announce('I am far away!');
              },
            ),
            ...[for (var i = 0; i <= radioStartCoordinates.y; i++) i].map(
              (final i) => RoomObjectStep(
                onStep: (final state, final object, final coordinates) {
                  final surface = state.getSurfaceAt(coordinates);
                  final destination = coordinates.north;
                  if (surface != null) {
                    final footstepSound = surface.footstepSounds
                        .randomElement();
                    final soundSettings = state.getSoundSettings(
                      coordinates: destination,
                      fullVolume: footstepSound.volume,
                      panMultiplier: object.panMultiplier,
                      maxDistance: object.maxDistance,
                    );
                    context.playSound(
                      footstepSound.copyWith(
                        position: SoundPositionPanned(soundSettings.pan),
                        relativePlaySpeed: soundSettings.playbackSpeed,
                        volume: soundSettings.volume,
                      ),
                    );
                  }
                  state.moveObject(object, destination);
                },
              ),
            ),
            RoomObjectStep(
              onStep: (final state, final object, final coordinates) {
                context.announce('I am home!');
              },
            ),
          ],
          onApproach: () => context.announce('Hello there.'),
          onLeave: () => context.announce('Goodbye, then.'),
        ),
      ],
    );
    return RoomWidgetBuilder(
      room: room,
      builder: (final context, final state) {
        void startMoving(final MovingDirection? direction) {
          if (direction == null) {
            state.stopPlayer();
          } else {
            state.startPlayer(direction);
          }
        }

        return SimpleScaffold(
          title: room.title,
          body: Column(
            children: [
              GameShortcuts(
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
                    shortcut: GameShortcutsShortcut.arrowUp,
                    onStart: (final innerContext) {
                      state.startPlayer(MovingDirection.forwards);
                    },
                    onStop: (final innerContext) => state.stopPlayer(),
                  ),
                  GameShortcut(
                    title: 'Move south',
                    shortcut: GameShortcutsShortcut.arrowDown,
                    onStart: (final innerContext) {
                      state.startPlayer(MovingDirection.backwards);
                    },
                    onStop: (final innerContext) => state.stopPlayer(),
                  ),
                  GameShortcut(
                    title: 'Move east',
                    shortcut: GameShortcutsShortcut.arrowRight,
                    onStart: (final innerContext) {
                      state.startPlayer(MovingDirection.right);
                    },
                    onStop: (final innerContext) => state.stopPlayer(),
                  ),
                  GameShortcut(
                    title: 'Move west',
                    shortcut: GameShortcutsShortcut.arrowLeft,
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
                    onStart: (final innerContext) async {
                      state.pause();
                      await innerContext.pushWidgetBuilder(
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
                      );
                      state.unpause();
                    },
                  ),
                ],
                child: const Text('Keyboard'),
              ),
              Row(
                children: [
                  DirectionArrow(
                    getDirection: () => state.movingDirection,
                    startMoving: startMoving,
                    direction: MovingDirection.left,
                  ),
                  DirectionArrow(
                    getDirection: () => state.movingDirection,
                    startMoving: startMoving,
                    direction: MovingDirection.backwards,
                  ),
                  DirectionArrow(
                    getDirection: () => state.movingDirection,
                    startMoving: startMoving,
                    direction: MovingDirection.forwards,
                  ),
                  DirectionArrow(
                    getDirection: () => state.movingDirection,
                    startMoving: startMoving,
                    direction: MovingDirection.right,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: LoadingScreen.new,
      error: ErrorScreen.withPositional,
    );
  }

  /// The function to call when the player hits a wall.
  void onWall(final BuildContext context) =>
      context.announce('You cannot go that way.');
}
