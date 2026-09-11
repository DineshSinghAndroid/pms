import 'package:equatable/equatable.dart';

import '../../models/digital_studio_asset_model.dart';
import '../../models/digital_studio_crew_request_model.dart';
import '../../models/user_model.dart';

abstract class DigitalStudioState extends Equatable {
  const DigitalStudioState();

  @override
  List<Object?> get props => [];
}

class DigitalStudioInitial extends DigitalStudioState {
  const DigitalStudioInitial();
}

class DigitalStudioLoading extends DigitalStudioState {
  const DigitalStudioLoading();
}

class DigitalStudioLoaded extends DigitalStudioState {
  final List<DigitalStudioAssetModel> assets;
  final List<DigitalStudioCrewRequestModel> crewRequests;
  final List<DigitalStudioCrewRequestModel> schedules;
  final List<UserModel> crewMembers;
  final List<DigitalStudioAssetModel> availableAssets;
  final String? actionSuccessMessage;
  final String? errorMessage;

  const DigitalStudioLoaded({
    required this.assets,
    required this.crewRequests,
    required this.schedules,
    this.crewMembers = const [],
    this.availableAssets = const [],
    this.actionSuccessMessage,
    this.errorMessage,
  });

  DigitalStudioLoaded copyWith({
    List<DigitalStudioAssetModel>? assets,
    List<DigitalStudioCrewRequestModel>? crewRequests,
    List<DigitalStudioCrewRequestModel>? schedules,
    List<UserModel>? crewMembers,
    List<DigitalStudioAssetModel>? availableAssets,
    String? actionSuccessMessage,
    String? errorMessage,
  }) {
    return DigitalStudioLoaded(
      assets: assets ?? this.assets,
      crewRequests: crewRequests ?? this.crewRequests,
      schedules: schedules ?? this.schedules,
      crewMembers: crewMembers ?? this.crewMembers,
      availableAssets: availableAssets ?? this.availableAssets,
      actionSuccessMessage: actionSuccessMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    assets,
    crewRequests,
    schedules,
    crewMembers,
    availableAssets,
    actionSuccessMessage,
    errorMessage,
  ];
}

class DigitalStudioError extends DigitalStudioState {
  final String errorMessage;

  const DigitalStudioError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
