// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Me extends Me {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final BuiltList<String> householdIds;
  @override
  final String? currentHouseholdId;

  factory _$Me([void Function(MeBuilder)? updates]) =>
      (MeBuilder()..update(updates))._build();

  _$Me._(
      {required this.uid,
      this.email,
      this.displayName,
      required this.householdIds,
      this.currentHouseholdId})
      : super._();
  @override
  Me rebuild(void Function(MeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MeBuilder toBuilder() => MeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Me &&
        uid == other.uid &&
        email == other.email &&
        displayName == other.displayName &&
        householdIds == other.householdIds &&
        currentHouseholdId == other.currentHouseholdId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, uid.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, householdIds.hashCode);
    _$hash = $jc(_$hash, currentHouseholdId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Me')
          ..add('uid', uid)
          ..add('email', email)
          ..add('displayName', displayName)
          ..add('householdIds', householdIds)
          ..add('currentHouseholdId', currentHouseholdId))
        .toString();
  }
}

class MeBuilder implements Builder<Me, MeBuilder> {
  _$Me? _$v;

  String? _uid;
  String? get uid => _$this._uid;
  set uid(String? uid) => _$this._uid = uid;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  ListBuilder<String>? _householdIds;
  ListBuilder<String> get householdIds =>
      _$this._householdIds ??= ListBuilder<String>();
  set householdIds(ListBuilder<String>? householdIds) =>
      _$this._householdIds = householdIds;

  String? _currentHouseholdId;
  String? get currentHouseholdId => _$this._currentHouseholdId;
  set currentHouseholdId(String? currentHouseholdId) =>
      _$this._currentHouseholdId = currentHouseholdId;

  MeBuilder() {
    Me._defaults(this);
  }

  MeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _uid = $v.uid;
      _email = $v.email;
      _displayName = $v.displayName;
      _householdIds = $v.householdIds.toBuilder();
      _currentHouseholdId = $v.currentHouseholdId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Me other) {
    _$v = other as _$Me;
  }

  @override
  void update(void Function(MeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Me build() => _build();

  _$Me _build() {
    _$Me _$result;
    try {
      _$result = _$v ??
          _$Me._(
            uid: BuiltValueNullFieldError.checkNotNull(uid, r'Me', 'uid'),
            email: email,
            displayName: displayName,
            householdIds: householdIds.build(),
            currentHouseholdId: currentHouseholdId,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'householdIds';
        householdIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'Me', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
