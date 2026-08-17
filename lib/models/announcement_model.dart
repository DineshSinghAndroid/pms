import 'package:equatable/equatable.dart';

/// Announcement Data Model
class AnnouncementModel extends Equatable {
  final bool success;
  final String message;
  final String author;
  final DateTime? updatedAt;

  const AnnouncementModel({
    required this.success,
    required this.message,
    required this.author,
    this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      author: json['author'] as String? ?? 'Super Admin',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'author': author,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [success, message, author, updatedAt];
}
