// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friendship.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Friendship _$FriendshipFromJson(Map<String, dynamic> json) => _Friendship(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  friendId: json['friend_id'] as String,
  status: $enumDecode(
    _$FriendshipStatusEnumMap,
    json['status'],
    unknownValue: FriendshipStatus.pending,
  ),
  requestedAt: localDateTimeFromJson(json['requested_at'] as String),
  respondedAt: nullableLocalDateTimeFromJson(json['responded_at'] as String?),
);

Map<String, dynamic> _$FriendshipToJson(_Friendship instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'friend_id': instance.friendId,
      'status': _$FriendshipStatusEnumMap[instance.status]!,
      'requested_at': dateTimeToJson(instance.requestedAt),
      'responded_at': nullableDateTimeToJson(instance.respondedAt),
    };

const _$FriendshipStatusEnumMap = {
  FriendshipStatus.pending: 'pending',
  FriendshipStatus.accepted: 'accepted',
  FriendshipStatus.rejected: 'rejected',
  FriendshipStatus.blocked: 'blocked',
};
