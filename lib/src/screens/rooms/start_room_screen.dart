import 'dart:math';

import 'package:backstreets_widgets/extensions.dart';
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
    return RoomScreen(
      room: Room(
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
                    context.announce('${coordinates.y}');
                    state.moveObject(object, coordinates.south);
                  },
                ),
              ),
              ...[for (var i = 0; i <= radioStartCoordinates.y; i++) i].map(
                (final i) => RoomObjectStep(
                  onStep: (final state, final object, final coordinates) {
                    context.announce('${coordinates.y}');
                    state.moveObject(object, coordinates.north);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
