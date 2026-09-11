import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/product_type_repository.dart';
import 'product_type_event.dart';
import 'product_type_state.dart';

class ProductTypeBloc extends Bloc<ProductTypeEvent, ProductTypeState> {
  final ProductTypeRepository repository;

  ProductTypeBloc({required this.repository})
    : super(const ProductTypeInitial()) {
    on<FetchProductTypesEvent>(_onFetchProductTypes);
    on<RefreshProductTypesEvent>(_onRefreshProductTypes);
    on<CreateProductTypeEvent>(_onCreateProductType);
    on<UpdateProductTypeEvent>(_onUpdateProductType);
    on<DeleteProductTypeEvent>(_onDeleteProductType);
  }

  Future<void> _onFetchProductTypes(
    FetchProductTypesEvent event,
    Emitter<ProductTypeState> emit,
  ) async {
    emit(const ProductTypeLoading());
    try {
      final types = await repository.getProductTypes(
        categoryId: event.categoryId,
      );
      emit(ProductTypeLoaded(productTypes: types));
    } catch (e) {
      emit(
        ProductTypeError(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onRefreshProductTypes(
    RefreshProductTypesEvent event,
    Emitter<ProductTypeState> emit,
  ) async {
    try {
      final types = await repository.getProductTypes(
        categoryId: event.categoryId,
      );
      emit(ProductTypeLoaded(productTypes: types));
    } catch (e) {
      emit(
        ProductTypeError(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onCreateProductType(
    CreateProductTypeEvent event,
    Emitter<ProductTypeState> emit,
  ) async {
    try {
      await repository.createProductType(event.payload);
      final types = await repository.getProductTypes();
      emit(ProductTypeLoaded(productTypes: types));
    } catch (e) {
      emit(
        ProductTypeError(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateProductType(
    UpdateProductTypeEvent event,
    Emitter<ProductTypeState> emit,
  ) async {
    try {
      await repository.updateProductType(event.productTypeId, event.payload);
      final types = await repository.getProductTypes();
      emit(ProductTypeLoaded(productTypes: types));
    } catch (e) {
      emit(
        ProductTypeError(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onDeleteProductType(
    DeleteProductTypeEvent event,
    Emitter<ProductTypeState> emit,
  ) async {
    try {
      await repository.deleteProductType(event.productTypeId);
      final types = await repository.getProductTypes();
      emit(ProductTypeLoaded(productTypes: types));
    } catch (e) {
      emit(
        ProductTypeError(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}
