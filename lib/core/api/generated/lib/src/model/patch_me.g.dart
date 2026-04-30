// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_me.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PatchMe extends PatchMe {
  @override
  final String? currentHouseholdId;
  @override
  final String? displayName;

  factory _$PatchMe([void Function(PatchMeBuilder)? updates]) =>
      (PatchMeBuilder()..update(updates))._build();

  _$PatchMe._({this.currentHouseholdId, this.displayName}) : super._();
  @override
  PatchMe rebuild(void Function(PatchMeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PatchMeBuilder toBuilder() => PatchMeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PatchMe &&
        currentHouseholdId == other.currentHouseholdId &&
        displayName == other.displayName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, currentHouseholdId.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PatchMe')
          ..add('currentHouseholdId', currentHouseholdId)
          ..add('displayName', displayName))
        .toString();
  }
}

class PatchMeBuilder implements Builder<PatchMe, PatchMeBuilder> {
  _$PatchMe? _$v;

  String? _currentHouseholdId;
  String? get currentHouseholdId => _$this._currentHouseholdId;
  set currentHouseholdId(String? currentHouseholdId) =>
      _$this._currentHouseholdId = currentHouseholdId;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  PatchMeBuilder() {
    PatchMe._defaults(this);
  }

  PatchMeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _currentHouseholdId = $v.currentHouseholdId;
      _displayName = $v.displayName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PatchMe other) {
    _$v = other as _$PatchMe;
  }

  @override
  void update(void Function(PatchMeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PatchMe build() => _build();

  _$PatchMe _build() {
    final _$result = _$v ??
        _$PatchMe._(
          currentHouseholdId: currentHouseholdId,
          displayName: displayName,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
