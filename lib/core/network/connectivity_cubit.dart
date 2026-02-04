import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:recall/core/network/connectivity_service.dart';

// States
abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object> get props => [];
}

class ConnectivityInitial extends ConnectivityState {}

class ConnectivityOnline extends ConnectivityState {}

class ConnectivityOffline extends ConnectivityState {}

// Cubit
class ConnectivityCubit extends Cubit<ConnectivityState> {
  final ConnectivityService _connectivityService;
  StreamSubscription? _subscription;

  ConnectivityCubit({required ConnectivityService connectivityService})
    : _connectivityService = connectivityService,
      super(ConnectivityInitial()) {
    _monitorConnection();
  }

  void _monitorConnection() {
    _subscription = _connectivityService.onStatusChange.listen((status) {
      if (status == InternetStatus.connected) {
        emit(ConnectivityOnline());
      } else {
        emit(ConnectivityOffline());
      }
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
