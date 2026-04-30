// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MeImpl _$$MeImplFromJson(Map<String, dynamic> json) => _$MeImpl(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      householdIds: (json['householdIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      currentHouseholdId: json['currentHouseholdId'] as String?,
    );

Map<String, dynamic> _$$MeImplToJson(_$MeImpl instance) => <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'displayName': instance.displayName,
      'householdIds': instance.householdIds,
      'currentHouseholdId': instance.currentHouseholdId,
    };
