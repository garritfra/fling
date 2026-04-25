import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
// ignore: unnecessary_import
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new dependencies are importable', () {
    expect(Connectivity, isNotNull);
    expect(ProviderContainer, isNotNull);
    expect(freezed, isNotNull);
    expect(GoRouter, isNotNull);
    expect(JsonSerializable, isNotNull);
    expect(SharedPreferences, isNotNull);
  });
}
