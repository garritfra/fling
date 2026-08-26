import 'package:fling/core/api/mutation_queue.dart';
import 'package:fling/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Subscribes to `mutationFailuresProvider` and shows a `SnackBar` via the
/// nearest `ScaffoldMessenger` for every terminal mutation failure.
///
/// Mounted once near the app root so the design spec §7.5 step 5
/// ("on failure: surface a FlingErrorSnackBar") has somewhere to land —
/// without forcing every call site to wrap `enqueue` in a try/catch.
class MutationFailureListener extends ConsumerWidget {
  const MutationFailureListener({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<MutationFailure>>(
      mutationFailuresProvider,
      (_, next) => next.whenData((f) => _show(context, f)),
    );
    return child;
  }

  void _show(BuildContext context, MutationFailure f) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l10n = AppLocalizations.of(context);
    final headline = l10n?.status_error ?? 'Something went wrong.';
    messenger.showSnackBar(SnackBar(
      content: Text('$headline (${f.error.code})'),
    ));
  }
}
