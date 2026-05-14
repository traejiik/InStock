import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/app_flags_repository.dart';

final onboardingInitialStateProvider = Provider<bool>((ref) => false);

final appFlagsRepositoryProvider = Provider<AppFlagsRepository>(
  (ref) => throw UnimplementedError(
    'Override appFlagsRepositoryProvider in ProviderScope',
  ),
);

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(onboardingInitialStateProvider);

  bool get isComplete => state;

  Future<void> markComplete() async {
    await ref.read(appFlagsRepositoryProvider).markOnboardingComplete();
    state = true;
  }

  Future<void> reset() async {
    await ref.read(appFlagsRepositoryProvider).reset();
    state = false;
  }
}
