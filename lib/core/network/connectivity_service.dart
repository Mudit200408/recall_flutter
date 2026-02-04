import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  final InternetConnection _internetConnection = InternetConnection();

  Stream<InternetStatus> get onStatusChange =>
      _internetConnection.onStatusChange;

  Future<bool> get hasInternetAccess => _internetConnection.hasInternetAccess;
}
