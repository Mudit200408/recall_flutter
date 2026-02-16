import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:recall/features/auth/domain/repositories/auth_repository.dart';
import 'package:recall/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:recall/features/recall/domain/services/image_generation_service.dart';
import 'package:recall/core/network/connectivity_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => GoogleSignIn.instance);

  // Auth (Static, doesn't change)
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton(() => AuthBloc(authRepository: sl()));

  // Services
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => ImageGenerationService());
  sl.registerLazySingleton(() => ConnectivityService());
}
