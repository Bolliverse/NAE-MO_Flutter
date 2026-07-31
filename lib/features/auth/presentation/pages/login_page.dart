import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:nae_mo/features/auth/presentation/viewmodels/auth_view_model.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider).asData?.value;
    final isSubmitting = authState?.isSubmitting ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 64,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 343),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'NAE MO',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '나의 하루를 한눈에 정리해 보세요.\n계속하려면 로그인해 주세요.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    height: 1.5,
                                  ),
                        ),
                        const SizedBox(height: 48),
                        _OfficialSignInButton(
                          key: const Key('googleSignInButton'),
                          semanticLabel: 'Google로 로그인',
                          assetPath: isDark
                              ? 'assets/icons/google_sign_in_dark.png'
                              : 'assets/icons/google_sign_in_light.png',
                          isEnabled: !isSubmitting,
                          isLoading: authState?.pendingProvider ==
                              AuthProviderType.google,
                          onPressed: () => ref
                              .read(authViewModelProvider.notifier)
                              .signIn(AuthProviderType.google),
                        ),
                        const SizedBox(height: 12),
                        _OfficialSignInButton(
                          key: const Key('appleSignInButton'),
                          semanticLabel: 'Apple로 로그인',
                          assetPath: isDark
                              ? 'assets/images/apple_sign_in_white.png'
                              : 'assets/images/apple_sign_in_black.png',
                          isEnabled: !isSubmitting,
                          isLoading: authState?.pendingProvider ==
                              AuthProviderType.apple,
                          onPressed: () => ref
                              .read(authViewModelProvider.notifier)
                              .signIn(AuthProviderType.apple),
                        ),
                        if (authState?.errorMessage case final message?) ...[
                          const SizedBox(height: 20),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OfficialSignInButton extends StatelessWidget {
  final String semanticLabel;
  final String assetPath;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _OfficialSignInButton({
    required this.semanticLabel,
    required this.assetPath,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: isEnabled || isLoading ? 1 : 0.6,
          child: SizedBox(
            width: 180,
            height: 40,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: isEnabled ? onPressed : null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      assetPath,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                    if (isLoading)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.82),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
