import 'package:jeeb_app/core/infrastructure/api/api_service.dart';
import 'package:jeeb_app/features/search/data/models/search_result_model.dart';

abstract class SearchRemoteDataSource {
  Future<SearchResponseModel> search({
    required String query,
    int? page,
    int? limit,
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final AppApiServiceClient _apiClient;

  SearchRemoteDataSourceImpl(this._apiClient);

  @override
  Future<SearchResponseModel> search({
    required String query,
    int? page,
    int? limit,
  }) async {
    final response = await _apiClient.search(
      query: query,
      page: page,
      limit: limit,
    );
    return SearchResponseModel.fromJson(response.data);
  }
}
