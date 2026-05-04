// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ApiErrorError extends ApiErrorError {
  @override
  final String code;
  @override
  final String message;
  @override
  final JsonObject? details;

  factory _$ApiErrorError([void Function(ApiErrorErrorBuilder)? updates]) =>
      (ApiErrorErrorBuilder()..update(updates))._build();

  _$ApiErrorError._({required this.code, required this.message, this.details})
      : super._();
  @override
  ApiErrorError rebuild(void Function(ApiErrorErrorBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ApiErrorErrorBuilder toBuilder() => ApiErrorErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ApiErrorError &&
        code == other.code &&
        message == other.message &&
        details == other.details;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, details.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ApiErrorError')
          ..add('code', code)
          ..add('message', message)
          ..add('details', details))
        .toString();
  }
}

class ApiErrorErrorBuilder
    implements Builder<ApiErrorError, ApiErrorErrorBuilder> {
  _$ApiErrorError? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  JsonObject? _details;
  JsonObject? get details => _$this._details;
  set details(JsonObject? details) => _$this._details = details;

  ApiErrorErrorBuilder() {
    ApiErrorError._defaults(this);
  }

  ApiErrorErrorBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _message = $v.message;
      _details = $v.details;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ApiErrorError other) {
    _$v = other as _$ApiErrorError;
  }

  @override
  void update(void Function(ApiErrorErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ApiErrorError build() => _build();

  _$ApiErrorError _build() {
    final _$result = _$v ??
        _$ApiErrorError._(
          code: BuiltValueNullFieldError.checkNotNull(
              code, r'ApiErrorError', 'code'),
          message: BuiltValueNullFieldError.checkNotNull(
              message, r'ApiErrorError', 'message'),
          details: details,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
