import 'dart:math';

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
    return RoomScreen(
      room: Room(
        title: 'Living Room',
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
            startCoordinates: const Point(5, 9),
            ambiance: ambiances.radio.asSound(destroy: false, looping: true),
          ),
        ],
      ),
    );
  }
}
