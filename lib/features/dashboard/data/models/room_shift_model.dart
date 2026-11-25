/// Models for Room Shift request and response.
class RoomShiftRequestPayload {
  final int residentId;
  final String reason;
  final String preferredRoomType;
  final int? requestedRoomId;
  final String expectedMoveDate;
  final String? additionalNotes;
  final String status;

  RoomShiftRequestPayload({
    required this.residentId,
    required this.reason,
    required this.preferredRoomType,
    this.requestedRoomId,
    required this.expectedMoveDate,
    this.additionalNotes,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'resident_id': residentId,
      'reason': reason,
      'preferred_room_type': preferredRoomType,
      if (requestedRoomId != null) 'requested_room_id': requestedRoomId,
      'expected_move_date': expectedMoveDate,
      if (additionalNotes != null && additionalNotes!.isNotEmpty)
        'additional_notes': additionalNotes,
      'status': status,
    };
  }
}

class RoomShiftItemModel {
  final int? id;
  final int? pgId;
  final int? branchId;
  final String? branchName;
  final int? stayId;
  final int? residentId;
  final String? residentName;
  final String? currentRoomNo;
  final String? currentRoomType;
  final String? requestedRoomNo;
  final String? requestedRoomType;
  final String? reason;
  final String? preferredRoomType;
  final int? requestedRoomId;
  final String? targetRoom;
  final String? expectedMoveDate;
  final String? additionalNotes;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  RoomShiftItemModel({
    this.id,
    this.pgId,
    this.branchId,
    this.branchName,
    this.stayId,
    this.residentId,
    this.residentName,
    this.currentRoomNo,
    this.currentRoomType,
    this.requestedRoomNo,
    this.requestedRoomType,
    this.reason,
    this.preferredRoomType,
    this.requestedRoomId,
    this.targetRoom,
    this.expectedMoveDate,
    this.additionalNotes,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory RoomShiftItemModel.fromJson(Map<String, dynamic> json) {
    String? targetRoomStr;
    String? reqRoomNo;
    String? reqRoomType;

    if (json['requested_room'] is Map<String, dynamic>) {
      final reqRoom = json['requested_room'] as Map<String, dynamic>;
      reqRoomNo = reqRoom['room_no']?.toString();
      reqRoomType = reqRoom['room_type']?.toString();
      if (reqRoomNo != null && reqRoomNo.isNotEmpty) {
        targetRoomStr = 'Room $reqRoomNo';
      }
    }

    targetRoomStr ??= json['target_room']?.toString() ??
        (json['requested_room_id'] != null ? 'Room ${json['requested_room_id']}' : null) ??
        json['preferred_room_type']?.toString() ??
        'Any Available Room';

    String? curRoomNo;
    String? curRoomType;
    if (json['current_room'] is Map<String, dynamic>) {
      final curRoom = json['current_room'] as Map<String, dynamic>;
      curRoomNo = curRoom['room_no']?.toString();
      curRoomType = curRoom['room_type']?.toString();
    }

    String? resName;
    int? resId = json['resident_id'] as int?;
    if (json['resident'] is Map<String, dynamic>) {
      final res = json['resident'] as Map<String, dynamic>;
      resId ??= res['id'] as int?;
      resName = res['name']?.toString();
    }

    return RoomShiftItemModel(
      id: json['id'] as int?,
      pgId: json['pg_id'] as int?,
      branchId: json['branch_id'] as int?,
      branchName: json['branch_name']?.toString(),
      stayId: json['stay_id'] as int?,
      residentId: resId,
      residentName: resName,
      currentRoomNo: curRoomNo,
      currentRoomType: curRoomType,
      requestedRoomNo: reqRoomNo,
      requestedRoomType: reqRoomType,
      reason: json['reason']?.toString(),
      preferredRoomType: json['preferred_room_type']?.toString(),
      requestedRoomId: json['requested_room_id'] as int? ??
          (json['requested_room'] is Map<String, dynamic>
              ? (json['requested_room'] as Map<String, dynamic>)['id'] as int?
              : null),
      targetRoom: targetRoomStr,
      expectedMoveDate: json['expected_move_date']?.toString(),
      additionalNotes: json['additional_notes']?.toString() ?? json['notes']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pg_id': pgId,
        'branch_id': branchId,
        'branch_name': branchName,
        'stay_id': stayId,
        'resident_id': residentId,
        'resident_name': residentName,
        'current_room_no': currentRoomNo,
        'current_room_type': currentRoomType,
        'requested_room_no': requestedRoomNo,
        'requested_room_type': requestedRoomType,
        'reason': reason,
        'preferred_room_type': preferredRoomType,
        'requested_room_id': requestedRoomId,
        'target_room': targetRoom,
        'expected_move_date': expectedMoveDate,
        'additional_notes': additionalNotes,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
