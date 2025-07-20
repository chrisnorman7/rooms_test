import 'package:backstreets_widgets/extensions.dart';
import 'package:backstreets_widgets/screens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:rooms_test/rooms_test.dart';

/// The home screen for the app.
class HomeScreen extends StatelessWidget {
  /// Create an instance.
  const HomeScreen({super.key});

  /// Build a widget.
  @override
  Widget build(final BuildContext context) {
    if (kIsWeb) {
      RendererBinding.instance.ensureSemantics();
      return SimpleScaffold(
        title: 'Enable Audio',
        body: Center(
          child: IconButton(
            onPressed: () async {
              await SoLoud.instance.init();
              if (context.mounted) {
                await context.pushWidgetBuilder((_) => const StartRoomScreen());
              }
            },
            icon: const Icon(Icons.play_arrow_rounded),
            autofocus: true,
            tooltip: 'Start game',
          ),
        ),
      );
    }
    return const StartRoomScreen();
  }
}
