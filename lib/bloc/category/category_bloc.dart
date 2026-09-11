import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/category_repository.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository repository;

  CategoryBloc({required this.repository}) : super(const CategoryInitial()) {
    on<FetchCategoriesEvent>(_onFetchCategories);
    on<RefreshCategoriesEvent>(_onRefreshCategories);
    on<CreateCategoryEvent>(_onCreateCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
  }

  Future<void> _onFetchCategories(
    FetchCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading());
    try {
      final categories = await repository.getCategories();
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(
        CategoryError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onRefreshCategories(
    RefreshCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final categories = await repository.getCategories();
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(
        CategoryError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onCreateCategory(
    CreateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await repository.createCategory(event.payload);
      final categories = await repository.getCategories();
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(
        CategoryError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await repository.updateCategory(event.categoryId, event.payload);
      final categories = await repository.getCategories();
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(
        CategoryError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await repository.deleteCategory(event.categoryId);
      final categories = await repository.getCategories();
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(
        CategoryError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }
}
