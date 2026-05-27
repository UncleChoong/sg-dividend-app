import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/data/universe_repository.dart';
import 'package:sg_dividend/ui/input_screen.dart';

final universeRepoProvider = Provider((_) => UniverseRepository());
final universeProvider = FutureProvider<Universe>((ref) async {
  return ref.read(universeRepoProvider).load();
});

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(universeProvider);
    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.warning_amber, size: 48),
              const SizedBox(height: 12),
              Text('Could not load data: $e'),
            ]),
          )),
          data: (u) => InputScreen(universe: u),
        ),
      ),
    );
  }
}
