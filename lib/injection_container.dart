//  Global Service Locator
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:recall/features/auth/domain/repositories/auth_repository.dart';
import 'package:recall/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:recall/features/recall/presentation/bloc/deck/deck_bloc.dart';
import 'package:recall/features/recall/presentation/bloc/quiz/quiz_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => GoogleSignIn.instance);

  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton(() => AuthBloc(authRepository: sl()));

  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(
    () => QuizBloc(repository: sl(), notificationService: sl()),
  );
  sl.registerLazySingleton(() => DeckBloc(repository: sl()));
}
