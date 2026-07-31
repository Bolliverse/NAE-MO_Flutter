import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:nae_mo/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('restores a signed-in session after the provider container is recreated',
      () async {
    final previousPlatform = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() {
      SharedPreferencesAsyncPlatform.instance = previousPlatform;
    });

    final firstContainer = ProviderContainer();
    await firstContainer.read(authViewModelProvider.future);
    await firstContainer
        .read(authViewModelProvider.notifier)
        .signIn(AuthProviderType.apple);

    final signedInState = firstContainer.read(authViewModelProvider).value!;
    final signedInSession = signedInState.session as AuthenticatedSession;
    expect(signedInSession.provider, AuthProviderType.apple);
    firstContainer.dispose();

    final restartedContainer = ProviderContainer();
    addTearDown(restartedContainer.dispose);

    final restoredState =
        await restartedContainer.read(authViewModelProvider.future);

    final restoredSession = restoredState.session as AuthenticatedSession;
    expect(restoredSession.provider, AuthProviderType.apple);
  });
}
