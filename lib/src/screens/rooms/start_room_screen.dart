import 'dart:math';

import 'package:backstreets_widgets/extensions.dart';
import 'package:backstreets_widgets/screens.dart';
import 'package:backstreets_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_games/flutter_audio_games.dart';
import 'package:rooms_test/rooms_test.dart';

/// The screen for the first room.
class StartRoomScreen extends StatelessWidget {
  /// Create an instance.
  const StartRoomScreen({super.key});

  /// Build the widget.
  @override
  Widget build(final BuildContext context) {
    final ambiances = Assets.sounds.ambiances;
    const radioStartCoordinates = Point(5, 9);
    final room = Room(
      title: 'Living Room',
      startingCoordinates: const Point(5, 5),
      footstepSoundNames: Assets.sounds.footsteps.linoleum.values,
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
                  final footstepSound = state.room.footstepSoundNames
                      .randomElement()
                      .asSound(destroy: true);
                  final destination = coordinates.south;
                  final soundSettings = state.getSoundSettings(
                    coordinates: destination,
                    fullVolume: footstepSound.volume,
                    panMultiplier: object.panMultiplier,
                    distanceAttenuation: object.distanceAttenuation,
                  );
                  context.playSound(
                    footstepSound.copyWith(
                      position: SoundPositionPanned(soundSettings.pan),
                      relativePlaySpeed: soundSettings.playbackSpeed,
                      volume: soundSettings.volume,
                    ),
                  );
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
                  final footstepSound = state.room.footstepSoundNames
                      .randomElement()
                      .asSound(destroy: true);
                  final destination = coordinates.north;
                  final soundSettings = state.getSoundSettings(
                    coordinates: destination,
                    fullVolume: footstepSound.volume,
                    panMultiplier: object.panMultiplier,
                    distanceAttenuation: object.distanceAttenuation,
                  );
                  state.moveObject(object, destination);
                  context.playSound(
                    footstepSound.copyWith(
                      position: SoundPositionPanned(soundSettings.pan),
                      relativePlaySpeed: soundSettings.playbackSpeed,
                      volume: soundSettings.volume,
                    ),
                  );
                },
              ),
            ),
            RoomObjectStep(
              onStep: (final state, final object, final coordinates) {
                context.announce('I am home!');
              },
            ),
          ],
        ),
      ],
    );
    return SimpleScaffold(
      title: room.title,
      body: RoomWidgetBuilder(
        room: room,
        builder: (final context, final state) => GameShortcuts(
          shortcuts: [
            GameShortcut(
              title: 'Announce coordinates',
              shortcut: GameShortcutsShortcut.keyC,
              onStart: (final innerContext) => context.announce(
                '${state.playerCoordinates.x}, ${state.playerCoordinates.y}',
              ),
            ),
            GameShortcut(
              title: 'Move north',
              shortcut: GameShortcutsShortcut.arrowUp,
              onStart: (final innerContext) {
                state.startPlayer(MovingDirection.forwards);
              },
              onStop: state.stopPlayer,
            ),
            GameShortcut(
              title: 'Move south',
              shortcut: GameShortcutsShortcut.arrowDown,
              onStart: (final innerContext) {
                state.startPlayer(MovingDirection.backwards);
              },
              onStop: state.stopPlayer,
            ),
            GameShortcut(
              title: 'Move east',
              shortcut: GameShortcutsShortcut.arrowRight,
              onStart: (final innerContext) {
                state.startPlayer(MovingDirection.right);
              },
              onStop: state.stopPlayer,
            ),
            GameShortcut(
              title: 'Move west',
              shortcut: GameShortcutsShortcut.arrowLeft,
              onStart: (final innerContext) {
                state.startPlayer(MovingDirection.left);
              },
              onStop: state.stopPlayer,
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
        loading: LoadingScreen.new,
        error: ErrorScreen.withPositional,
      ),
    );
  }
}
