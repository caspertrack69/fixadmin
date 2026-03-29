final class ApiPaths {
  static const authLogin = '/auth/login';
  static const authMe = '/auth/me';
  static const authLogout = '/auth/logout';

  static const kasirDashboard = '/kasir/dashboard';
  static const catalogTree = '/catalog/tree';
  static const variantsSearch = '/variants/search';

  static const transactions = '/transactions';
  static String transactionDetail(int id) => '$transactions/$id';

  static const stockIn = '/stock/in';

  const ApiPaths._();
}
