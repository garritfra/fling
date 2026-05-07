/// Constants identifying me-feature mutations on the wire and inside the
/// client-side mutation queue. Lifted out of the repo so callers, tests,
/// and overlay-keyed lookups all reference the same string.
class MeMutations {
  MeMutations._();

  /// `MutationSpec.type` for any patch against `/v1/me`.
  static const String patchType = 'me.patch';

  /// `MutationSpec.resourceKey` for the active user's me-document.
  static String resourceKey(String uid) => 'me/$uid';
}
