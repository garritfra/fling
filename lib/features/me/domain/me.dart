import 'package:freezed_annotation/freezed_annotation.dart';

part 'me.freezed.dart';
part 'me.g.dart';

@freezed
class Me with _$Me {
  const factory Me({
    required String uid,
    String? email,
    String? displayName,
    @Default(<String>[]) List<String> householdIds,
    String? currentHouseholdId,
  }) = _Me;

  factory Me.fromJson(Map<String, dynamic> json) => _$MeFromJson(json);

  factory Me.fromFirestoreDoc(String uid, Map<String, dynamic> data) {
    return Me(
      uid: uid,
      email: data['email'] as String?,
      displayName: data['display_name'] as String?,
      householdIds: List<String>.from(
        (data['household_ids'] ?? data['households'] ?? const <String>[]) as List,
      ),
      currentHouseholdId:
          (data['current_household_id'] ?? data['current_household']) as String?,
    );
  }
}
