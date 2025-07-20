import 'package:flutter_audio_games/flutter_audio_games.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// A class which holds settings for a sound.
class SoundSettings {
  /// Create an instance.
  const SoundSettings({
    required this.volume,
    required this.pan,
    required this.playbackSpeed,
  });

  /// The volume of the sound.
  final double volume;

  /// Returns `true` if this sound should be muted.
  ///
  /// The [isMuted] getter is a shortcut for `volume <= 0.0`.
  bool get isMuted => volume <= 0.0;

  /// The pan of the sound.
  ///
  /// The [pan] is between `-1.0` and `1.0`, where `-1.0` is full left, `0.0` is
  /// center, and `1.0` is full right.
  final double pan;

  /// The playback speed for the sound.
  ///
  /// The [playbackSpeed] is usually `1.0`, but will be
  /// `room.behindPlaybackRate` if the sound is behind the player.
  final double playbackSpeed;

  /// Apply these settings to [handle].
  void apply({
    required final SoundHandle handle,
    required final Duration fade,
    required final Duration panFade,
    required final Duration speedFade,
  }) {
    if (isMuted) {
      handle.volume.fade(0.0, fade);
    } else {
      handle
        ..volume.fade(volume, fade)
        ..pan.fade(pan, panFade)
        ..relativePlaySpeed.fade(playbackSpeed, speedFade);
    }
  }
}
