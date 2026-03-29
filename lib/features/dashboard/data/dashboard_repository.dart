import '../../../core/network/api_client.dart';
import '../models/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> fetchDashboard();
}

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<DashboardSummary> fetchDashboard() {
    return _apiClient.getObject<DashboardSummary>(
      '/kasir/dashboard',
      parser: DashboardSummary.fromJson,
    );
  }
}
