import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchCategoriesEvent extends CategoryEvent {
  const FetchCategoriesEvent();
}

class RefreshCategoriesEvent extends CategoryEvent {
  const RefreshCategoriesEvent();
}

class CreateCategoryEvent extends CategoryEvent {
  final Map<String, dynamic> payload;

  const CreateCategoryEvent(this.payload);

  @override
  List<Object?> get props => [payload];
}

class UpdateCategoryEvent extends CategoryEvent {
  final int categoryId;
  final Map<String, dynamic> payload;

  const UpdateCategoryEvent({required this.categoryId, required this.payload});

  @override
  List<Object?> get props => [categoryId, payload];
}

class DeleteCategoryEvent extends CategoryEvent {
  final int categoryId;

  const DeleteCategoryEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}
