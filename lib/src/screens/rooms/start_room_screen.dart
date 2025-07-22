import 'dart:math';

import 'package:backstreets_widgets/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_games/flutter_audio_games.dart';
import 'package:rooms_test/rooms_test.dart';
import 'package:rooms_test/src/room_exit.dart';
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
      footstepSounds: footsteps.bootsLinoleum.values
          .map((final filename) => filename.asSound(destroy: true))
          .toList(),
      onEnter: (final state, final coordinates) =>
          context.announce('You enter the main room.'),
      onWall: (final state, final coordinates) => onWall(context),
    );
    return DefaultRoomScreen(
      getRoom: (final setRoom) {
        final room = Room(
          title: 'Living Room',
          surfaces: [
            surface1,
            RoomSurface(
              start: surface1.southeast.east,
              width: surface1.width,
              depth: surface1.depth,
              footstepSounds: footsteps.metalStep.values
                  .map((final filename) => filename.asSound(destroy: true))
                  .toList(),
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
              ambiance: ambiances.pump.asSound(
                destroy: false,
                looping: true,
                volume: 0.3,
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
                        context.playSound(
                          footstepSound.copyWith(
                            position: destination.soundPosition3d,
                            relativePlaySpeed:
                                (destination.y < state.playerCoordinates.y)
                                ? state.behindPlaybackSpeed
                                : 1.0,
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
                        context.playSound(
                          footstepSound.copyWith(
                            position: destination.soundPosition3d,
                            relativePlaySpeed:
                                (destination.y < state.playerCoordinates.y)
                                ? state.behindPlaybackSpeed
                                : 1.0,
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
              onApproach: (final state, final coordinates) =>
                  state.context.announce('Hello there.'),
              onLeave: (final state, final coordinates) =>
                  state.context.announce('Goodbye, then.'),
            ),
          ],
        );
        room.objects.add(
          RoomObject(
            name: 'Metal thing',
            startCoordinates: const Point(15, 5),
            ambiance: ambiances.metal.asSound(
              destroy: false,
              looping: true,
              volume: 0.5,
            ),
            onActivate: RoomExit(
              setRoom: (final state, final coordinates) => setRoom(
                Room(
                  title: 'The Second Room',
                  surfaces: [
                    RoomSurface(
                      start: const Point(0, 0),
                      width: 5,
                      depth: 5,
                      footstepSounds: footsteps.ice.values.asSoundList(
                        destroy: true,
                      ),
                      onWall: (final state, final coordinates) =>
                          state.context.announce('You cannot go that way.'),
                    ),
                  ],
                  objects: [
                    RoomObject(
                      name: 'Door to get back',
                      startCoordinates: const Point(3, 3),
                      ambiance: ambiances.pump.asSound(
                        destroy: false,
                        looping: true,
                        volume: 0.3,
                      ),
                      onActivate: RoomExit(
                        setRoom: (final state, final _) =>
                            setRoom(room, coordinates: coordinates),
                        useSound: Assets.sounds.interface.machineSwitch.asSound(
                          destroy: true,
                        ),
                      ).use,
                    ),
                  ],
                ),
              ),
              useSound: Assets.sounds.interface.machineSwitch.asSound(
                destroy: true,
              ),
            ).use,
          ),
        );
        return room;
      },
    );
  }

  /// The function to call when the player hits a wall.
  void onWall(final BuildContext context) =>
      context.announce('You cannot go that way.');
}
