// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Profile',
  json,
  ($checkedConvert) {
    final val = Profile(
      userId: $checkedConvert('user_id', (v) => v as String),
      firstName: $checkedConvert('first_name', (v) => v as String),
      countryCode: $checkedConvert('country_code', (v) => v as String),
      locale: $checkedConvert('locale', (v) => v as String),
      zoneId: $checkedConvert('zone_id', (v) => v as String?),
      avatarKey: $checkedConvert('avatar_key', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'userId': 'user_id',
    'firstName': 'first_name',
    'countryCode': 'country_code',
    'zoneId': 'zone_id',
    'avatarKey': 'avatar_key',
  },
);
