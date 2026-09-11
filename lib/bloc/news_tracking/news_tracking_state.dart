import 'package:equatable/equatable.dart';

import '../../models/newspaper_entry_model.dart';
import '../../models/newspaper_model.dart';
import '../../models/newspaper_size_model.dart';
import '../../models/wing_model.dart';

abstract class NewsTrackingState extends Equatable {
  const NewsTrackingState();

  @override
  List<Object?> get props => [];
}

class NewsTrackingInitial extends NewsTrackingState {}

class NewsTrackingLoading extends NewsTrackingState {}

class NewsTrackingLoaded extends NewsTrackingState {
  final List<NewspaperEntryModel> entries;
  final List<NewspaperModel> newspapers;
  final List<NewspaperSizeModel> sizes;
  final List<WingModel> wings;
  final Map<String, dynamic> pagination;
  final Map<String, dynamic> stats;
  final String? activeSearch;
  final int? activeWingId;
  final int? activeNewspaperId;
  final int? activeSizeId;
  final String? activeStartDate;
  final String? activeEndDate;

  const NewsTrackingLoaded({
    required this.entries,
    required this.newspapers,
    required this.sizes,
    required this.wings,
    this.pagination = const {},
    this.stats = const {},
    this.activeSearch,
    this.activeWingId,
    this.activeNewspaperId,
    this.activeSizeId,
    this.activeStartDate,
    this.activeEndDate,
  });

  int get totalEntries =>
      stats['total_entries'] as int? ??
      pagination['total'] as int? ??
      entries.length;

  int get thisMonthEntries => stats['this_month_entries'] as int? ?? 0;
  int get totalNewspapers => stats['total_newspapers'] as int? ?? newspapers.length;
  int get totalWingsTracked => stats['total_wings_tracked'] as int? ?? wings.length;

  NewsTrackingLoaded copyWith({
    List<NewspaperEntryModel>? entries,
    List<NewspaperModel>? newspapers,
    List<NewspaperSizeModel>? sizes,
    List<WingModel>? wings,
    Map<String, dynamic>? pagination,
    Map<String, dynamic>? stats,
    String? activeSearch,
    int? activeWingId,
    int? activeNewspaperId,
    int? activeSizeId,
    String? activeStartDate,
    String? activeEndDate,
  }) {
    return NewsTrackingLoaded(
      entries: entries ?? this.entries,
      newspapers: newspapers ?? this.newspapers,
      sizes: sizes ?? this.sizes,
      wings: wings ?? this.wings,
      pagination: pagination ?? this.pagination,
      stats: stats ?? this.stats,
      activeSearch: activeSearch ?? this.activeSearch,
      activeWingId: activeWingId ?? this.activeWingId,
      activeNewspaperId: activeNewspaperId ?? this.activeNewspaperId,
      activeSizeId: activeSizeId ?? this.activeSizeId,
      activeStartDate: activeStartDate ?? this.activeStartDate,
      activeEndDate: activeEndDate ?? this.activeEndDate,
    );
  }

  @override
  List<Object?> get props => [
    entries,
    newspapers,
    sizes,
    wings,
    pagination,
    stats,
    activeSearch,
    activeWingId,
    activeNewspaperId,
    activeSizeId,
    activeStartDate,
    activeEndDate,
  ];
}

class NewsTrackingActionSuccess extends NewsTrackingState {
  final String message;

  const NewsTrackingActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class NewsTrackingError extends NewsTrackingState {
  final String message;

  const NewsTrackingError(this.message);

  @override
  List<Object?> get props => [message];
}
