// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'me.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Me _$MeFromJson(Map<String, dynamic> json) {
  return _Me.fromJson(json);
}

/// @nodoc
mixin _$Me {
  String get uid => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  List<String> get householdIds => throw _privateConstructorUsedError;
  String? get currentHouseholdId => throw _privateConstructorUsedError;

  /// Serializes this Me to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Me
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MeCopyWith<Me> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeCopyWith<$Res> {
  factory $MeCopyWith(Me value, $Res Function(Me) then) =
      _$MeCopyWithImpl<$Res, Me>;
  @useResult
  $Res call(
      {String uid,
      String? email,
      String? displayName,
      List<String> householdIds,
      String? currentHouseholdId});
}

/// @nodoc
class _$MeCopyWithImpl<$Res, $Val extends Me> implements $MeCopyWith<$Res> {
  _$MeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Me
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = freezed,
    Object? displayName = freezed,
    Object? householdIds = null,
    Object? currentHouseholdId = freezed,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      householdIds: null == householdIds
          ? _value.householdIds
          : householdIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentHouseholdId: freezed == currentHouseholdId
          ? _value.currentHouseholdId
          : currentHouseholdId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MeImplCopyWith<$Res> implements $MeCopyWith<$Res> {
  factory _$$MeImplCopyWith(_$MeImpl value, $Res Function(_$MeImpl) then) =
      __$$MeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid,
      String? email,
      String? displayName,
      List<String> householdIds,
      String? currentHouseholdId});
}

/// @nodoc
class __$$MeImplCopyWithImpl<$Res> extends _$MeCopyWithImpl<$Res, _$MeImpl>
    implements _$$MeImplCopyWith<$Res> {
  __$$MeImplCopyWithImpl(_$MeImpl _value, $Res Function(_$MeImpl) _then)
      : super(_value, _then);

  /// Create a copy of Me
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = freezed,
    Object? displayName = freezed,
    Object? householdIds = null,
    Object? currentHouseholdId = freezed,
  }) {
    return _then(_$MeImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      householdIds: null == householdIds
          ? _value._householdIds
          : householdIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentHouseholdId: freezed == currentHouseholdId
          ? _value.currentHouseholdId
          : currentHouseholdId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MeImpl implements _Me {
  const _$MeImpl(
      {required this.uid,
      this.email,
      this.displayName,
      final List<String> householdIds = const <String>[],
      this.currentHouseholdId})
      : _householdIds = householdIds;

  factory _$MeImpl.fromJson(Map<String, dynamic> json) =>
      _$$MeImplFromJson(json);

  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  final List<String> _householdIds;
  @override
  @JsonKey()
  List<String> get householdIds {
    if (_householdIds is EqualUnmodifiableListView) return _householdIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_householdIds);
  }

  @override
  final String? currentHouseholdId;

  @override
  String toString() {
    return 'Me(uid: $uid, email: $email, displayName: $displayName, householdIds: $householdIds, currentHouseholdId: $currentHouseholdId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            const DeepCollectionEquality()
                .equals(other._householdIds, _householdIds) &&
            (identical(other.currentHouseholdId, currentHouseholdId) ||
                other.currentHouseholdId == currentHouseholdId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, uid, email, displayName,
      const DeepCollectionEquality().hash(_householdIds), currentHouseholdId);

  /// Create a copy of Me
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MeImplCopyWith<_$MeImpl> get copyWith =>
      __$$MeImplCopyWithImpl<_$MeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MeImplToJson(
      this,
    );
  }
}

abstract class _Me implements Me {
  const factory _Me(
      {required final String uid,
      final String? email,
      final String? displayName,
      final List<String> householdIds,
      final String? currentHouseholdId}) = _$MeImpl;

  factory _Me.fromJson(Map<String, dynamic> json) = _$MeImpl.fromJson;

  @override
  String get uid;
  @override
  String? get email;
  @override
  String? get displayName;
  @override
  List<String> get householdIds;
  @override
  String? get currentHouseholdId;

  /// Create a copy of Me
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MeImplCopyWith<_$MeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
