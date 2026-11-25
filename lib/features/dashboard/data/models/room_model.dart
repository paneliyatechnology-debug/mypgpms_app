/// Models for Rooms API response.
class RoomItemModel {
  final int id;
  final int? pgId;
  final String roomNo;
  final String? roomType;
  final int? capacity;
  final String? size;
  final String? status;
  final String? image;
  final String? imageUrl;
  final int? buildingId;
  final int? floorId;
  final int? branchId;
  final String? pgName;
  final String? branchName;
  final String? buildingName;
  final String? floorName;
  final int? floorNumber;
  final int? currentOccupants;
  final String? currentOccupantName;
  final int? availableBeds;
  final bool isAvailable;
  final String sharingLabel;
  final String displayLabel;

  RoomItemModel({
    required this.id,
    this.pgId,
    required this.roomNo,
    this.roomType,
    this.capacity,
    this.size,
    this.status,
    this.image,
    this.imageUrl,
    this.buildingId,
    this.floorId,
    this.branchId,
    this.pgName,
    this.branchName,
    this.buildingName,
    this.floorName,
    this.floorNumber,
    this.currentOccupants,
    this.currentOccupantName,
    this.availableBeds,
    this.isAvailable = true,
    required this.sharingLabel,
    required this.displayLabel,
  });

  factory RoomItemModel.fromJson(Map<String, dynamic> json) {
    final roomNoStr = json['room_no']?.toString() ?? '';
    final sharing = json['sharing_label']?.toString() ??
        (json['room_type'] != null
            ? '${json['room_type'].toString().capitalize()} Sharing'
            : 'Double Sharing');

    final bedsAvail = json['available_beds'] as int? ??
        (json['capacity'] is int && json['current_occupants'] is int
            ? (json['capacity'] as int) - (json['current_occupants'] as int)
            : 1);

    return RoomItemModel(
      id: json['id'] as int? ?? 0,
      pgId: json['pg_id'] as int?,
      roomNo: roomNoStr,
      roomType: json['room_type']?.toString(),
      capacity: json['capacity'] as int?,
      size: json['size']?.toString(),
      status: json['status']?.toString(),
      image: json['image']?.toString(),
      imageUrl: json['image_url']?.toString(),
      buildingId: json['building_id'] as int?,
      floorId: json['floor_id'] as int?,
      branchId: json['branch_id'] as int?,
      pgName: json['pg_name']?.toString(),
      branchName: json['branch_name']?.toString(),
      buildingName: json['building_name']?.toString(),
      floorName: json['floor_name']?.toString(),
      floorNumber: json['floor_number'] as int?,
      currentOccupants: json['current_occupants'] as int?,
      currentOccupantName: json['current_occupant_name']?.toString(),
      availableBeds: bedsAvail,
      isAvailable: json['is_available'] as bool? ?? (json['status'] == 'vacant' || bedsAvail > 0),
      sharingLabel: sharing,
      displayLabel: json['display_label']?.toString() ??
          'Room $roomNoStr ($sharing) - $bedsAvail beds available',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pg_id': pgId,
        'room_no': roomNo,
        'room_type': roomType,
        'capacity': capacity,
        'size': size,
        'status': status,
        'image': image,
        'image_url': imageUrl,
        'building_id': buildingId,
        'floor_id': floorId,
        'branch_id': branchId,
        'pg_name': pgName,
        'branch_name': branchName,
        'building_name': buildingName,
        'floor_name': floorName,
        'floor_number': floorNumber,
        'current_occupants': currentOccupants,
        'current_occupant_name': currentOccupantName,
        'available_beds': availableBeds,
        'is_available': isAvailable,
        'sharing_label': sharingLabel,
        'display_label': displayLabel,
      };
}

class RoomsResponseModel {
  final bool success;
  final String message;
  final List<RoomItemModel> data;

  RoomsResponseModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory RoomsResponseModel.fromJson(Map<String, dynamic> json) {
    final list = json['data'] is List ? json['data'] as List : [];
    return RoomsResponseModel(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: list
          .whereType<Map<String, dynamic>>()
          .map(RoomItemModel.fromJson)
          .toList(),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
