import 'package:equatable/equatable.dart';

abstract class NewsTrackingEvent extends Equatable {
  const NewsTrackingEvent();

  @override
  List<Object?> get props => [];
}

class FetchNewsTrackingDataEvent extends NewsTrackingEvent {
  final String? search;
  final int? wingId;
  final int? newspaperId;
  final int? sizeId;
  final String? startDate;
  final String? endDate;
  final int page;
  final String? phone;

  const FetchNewsTrackingDataEvent({
    this.search,
    this.wingId,
    this.newspaperId,
    this.sizeId,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.phone,
  });

  @override
  List<Object?> get props => [search, wingId, newspaperId, sizeId, startDate, endDate, page, phone];
}

class CreateNewsEntryEvent extends NewsTrackingEvent {
  final String adName;
  final String publishDate;
  final int? wingId;
  final int? newspaperId;
  final int? newspaperSizeId;
  final String? link1;
  final String? link2;
  final String? remark;
  final String? localFilePath;
  final String? phone;

  const CreateNewsEntryEvent({
    required this.adName,
    required this.publishDate,
    this.wingId,
    this.newspaperId,
    this.newspaperSizeId,
    this.link1,
    this.link2,
    this.remark,
    this.localFilePath,
    this.phone,
  });

  @override
  List<Object?> get props => [adName, publishDate, wingId, newspaperId, newspaperSizeId, link1, link2, remark, localFilePath, phone];
}

class UpdateNewsEntryEvent extends NewsTrackingEvent {
  final int id;
  final String adName;
  final String publishDate;
  final int? wingId;
  final int? newspaperId;
  final int? newspaperSizeId;
  final String? link1;
  final String? link2;
  final String? remark;
  final String? localFilePath;
  final String? phone;

  const UpdateNewsEntryEvent({
    required this.id,
    required this.adName,
    required this.publishDate,
    this.wingId,
    this.newspaperId,
    this.newspaperSizeId,
    this.link1,
    this.link2,
    this.remark,
    this.localFilePath,
    this.phone,
  });

  @override
  List<Object?> get props => [id, adName, publishDate, wingId, newspaperId, newspaperSizeId, link1, link2, remark, localFilePath, phone];
}

class DeleteNewsEntryEvent extends NewsTrackingEvent {
  final int id;
  final String? phone;

  const DeleteNewsEntryEvent({required this.id, this.phone});

  @override
  List<Object?> get props => [id, phone];
}

class CreateNewspaperMasterEvent extends NewsTrackingEvent {
  final String name;
  final String? phone;

  const CreateNewspaperMasterEvent({required this.name, this.phone});

  @override
  List<Object?> get props => [name, phone];
}

class CreateSizeMasterEvent extends NewsTrackingEvent {
  final String name;
  final String? phone;

  const CreateSizeMasterEvent({required this.name, this.phone});

  @override
  List<Object?> get props => [name, phone];
}
