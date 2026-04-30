//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'patch_me.g.dart';

/// PatchMe
///
/// Properties:
/// * [currentHouseholdId] 
/// * [displayName] 
@BuiltValue()
abstract class PatchMe implements Built<PatchMe, PatchMeBuilder> {
  @BuiltValueField(wireName: r'currentHouseholdId')
  String? get currentHouseholdId;

  @BuiltValueField(wireName: r'displayName')
  String? get displayName;

  PatchMe._();

  factory PatchMe([void updates(PatchMeBuilder b)]) = _$PatchMe;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PatchMeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PatchMe> get serializer => _$PatchMeSerializer();
}

class _$PatchMeSerializer implements PrimitiveSerializer<PatchMe> {
  @override
  final Iterable<Type> types = const [PatchMe, _$PatchMe];

  @override
  final String wireName = r'PatchMe';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PatchMe object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.currentHouseholdId != null) {
      yield r'currentHouseholdId';
      yield serializers.serialize(
        object.currentHouseholdId,
        specifiedType: const FullType(String),
      );
    }
    if (object.displayName != null) {
      yield r'displayName';
      yield serializers.serialize(
        object.displayName,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PatchMe object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PatchMeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'currentHouseholdId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.currentHouseholdId = valueDes;
          break;
        case r'displayName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayName = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PatchMe deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PatchMeBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

