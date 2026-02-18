import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:ffi';
import 'package:sqlite3/open.dart' as sqlite3;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/database/app_database.dart';
import 'package:recall/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:recall/features/auth/presentation/pages/login_page.dart';
import 'package:recall/features/recall/data/datasource/local_flashcard_datasource.dart';
import 'package:recall/features/recall/data/datasource/remote_flashcard_datasource.dart';
import 'package:recall/features/recall/data/repositories/flashcard_repository_impl.dart';
import 'package:recall/features/recall/data/service/gemini_ai_service.dart';
import 'package:recall/features/recall/data/service/local_ai_service.dart';
import 'package:recall/features/recall/data/service/model_management_service.dart';
import 'package:recall/features/recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/core/network/connectivity_cubit.dart';
import 'package:recall/core/network/connectivity_service.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/features/recall/domain/services/ai_service.dart';
import 'package:recall/features/recall/presentation/bloc/deck/deck_bloc.dart';
import 'package:recall/features/recall/presentation/pages/deck_list_page.dart';
import 'package:recall/features/recall/presentation/pages/model_selection_page.dart';
import 'package:recall/firebase_options.dart';
import 'package:recall/core/widgets/loader.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:responsive_scaler/responsive_scaler.dart';
import 'injection_container.dart' as di;
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(),
    providerApple: AppleDebugProvider(),
  );
  await di.init();
  ResponsiveScaler.init(
    designWidth: 448,
    designHeight: 937,
    minScale: 0.8,
    maxScale: 1.2,
  );

  const token = String.fromEnvironment('HUGGINGFACE_TOKEN');

  FlutterGemma.initialize(
    //huggingFaceToken: 'YOUR_HUGGINGFACE_TOKEN',
    huggingFaceToken: token.isNotEmpty ? token : null,
    maxDownloadRetries: 10,
  );

  if (Platform.isAndroid) {
    sqlite3.open.overrideFor(sqlite3.OperatingSystem.android, () {
      return DynamicLibrary.open('libsqlite3.so');
    });
  }

  final localDatabase = AppDatabase();

  runApp(MainApp(localDatabase: localDatabase));
}

class MainApp extends StatefulWidget {
  final AppDatabase localDatabase;
  const MainApp({super.key, required this.localDatabase});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Cache the guest model future so FutureBuilder doesn't re-fire on rebuilds
  Future<String?>? _guestModelFuture;

  ThemeData _buildTheme(bool isGuest) {
    final accentColor = isGuest
        ? const Color.fromARGB(255, 0, 255, 225)
        : const Color(0xFFCCFF00);

    return ThemeData(
      scaffoldBackgroundColor: Colors.white,
      primaryColor: accentColor,
      fontFamily: 'SpaceGrotesk',
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentColor,
        selectionColor: accentColor.withValues(alpha: 0.3),
        selectionHandleColor: accentColor,
      ),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => ConnectivityCubit(
            connectivityService: di.sl<ConnectivityService>(),
          ),
        ),
      ],
      child: ResponsiveBreakpoints.builder(
        breakpoints: [
          const Breakpoint(start: 0, end: 600, name: MOBILE),
          const Breakpoint(start: 601, end: 1200, name: TABLET),
          const Breakpoint(start: 1201, end: 1920, name: DESKTOP),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final bool isGuest = (authState is AuthGuest);
            // Reset cached future when leaving guest mode to prevent stale navigation
            if (!isGuest) {
              _guestModelFuture = null;
            }

            return MaterialApp(
              // Force full navigator recreation on auth state change to
              // dispose stale routes that reference removed providers.
              key: ValueKey(authState.runtimeType),
              theme: _buildTheme(isGuest),
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                child = ResponsiveScaler.scale(context: context, child: child!);

                if (authState is AuthAuthenticated || authState is AuthGuest) {
                  final String userId = authState is AuthAuthenticated
                      ? authState.user.uid
                      : "guest_login";

                  final AiService aiService = isGuest
                      ? LocalAIService()
                      : GeminiAiService();
                  return RepositoryProvider<FlashcardRepository>(
                    create: (context) => FlashcardRepositoryImpl(
                      localFlashcardDatasource: LocalFlashcardDatasource(
                        database: widget.localDatabase,
                      ),
                      remoteFlashcardDataSource: RemoteFlashcardDataSource(
                        firestore: di.sl(),
                        storage: di.sl(),
                        userId: userId,
                        httpClient: http.Client(),
                        imageService: di.sl(),
                      ),
                      aiService: aiService,
                      isGuestMode: isGuest,
                    ),
                    child: BlocProvider(
                      create: (context) => DeckBloc(
                        repository: context.read<FlashcardRepository>(),
                        notificationService: di.sl<NotificationService>(),
                        isGuest: isGuest,
                      )..add(LoadDecks()),
                      child: child,
                    ),
                  );
                }
                return child;
              },
              home: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthAuthenticated) {
                    return const DeckListPage(isGuest: false);
                  }
                  if (state is AuthGuest) {
                    _guestModelFuture ??= ModelManagementService()
                        .getActiveModelId();
                    return FutureBuilder<String?>(
                      future: _guestModelFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Scaffold(
                            body: Center(child: Loader(isGuest: true)),
                          );
                        }
                        final activeModelId = snapshot.data;
                        if (activeModelId != null && activeModelId.isNotEmpty) {
                          return const DeckListPage(isGuest: true);
                        }
                        return const ModelSelectionPage(isSettingsMode: true);
                      },
                    );
                  }
                  if (state is AuthLoading) {
                    return const Scaffold(
                      body: Center(child: Loader(isGuest: false)),
                    );
                  }
                  return const LoginPage();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
