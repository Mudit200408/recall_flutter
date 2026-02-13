import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:recall/features/auth/presentation/pages/login_page.dart';
import 'package:recall/features/recall/data/repositories/flashcard_repository_impl.dart';
import 'package:recall/features/recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/core/network/connectivity_cubit.dart';
import 'package:recall/core/network/connectivity_service.dart';
import 'package:recall/features/recall/presentation/bloc/deck/deck_bloc.dart';
import 'package:recall/features/recall/presentation/pages/deck_list_page.dart';
import 'package:recall/firebase_options.dart';
import 'package:recall/core/widgets/loader.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:responsive_scaler/responsive_scaler.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      scaffoldBackgroundColor: Colors.white,
      primaryColor: Color(0xFFCCFF00),
      fontFamily: 'SpaceGrotesk',
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Color.fromARGB(
          255,
          184,
          230,
          0,
        ), // Color of the blinking cursor
        selectionColor: Color(
          0xFFCCFF00,
        ).withValues(alpha: 0.3), // Color of highlighted text
        selectionHandleColor: Color(
          0xFFCCFF00,
        ), // Color of the "bubbles" at the ends of a selection
      ),
      // colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      useMaterial3: true,
    );
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
        child: MaterialApp(
          theme: theme,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            child = ResponsiveScaler.scale(context: context, child: child!);

            return BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState is AuthAuthenticated) {
                  return RepositoryProvider<FlashcardRepository>(
                    create: (context) => FlashcardRepositoryImpl(
                      firestore: di.sl(),
                      storage: di.sl(),
                      userId: authState.user.uid,
                      httpClient: http.Client(),
                      imageService: di.sl(),
                    ),
                    child: BlocProvider(
                      create: (context) => DeckBloc(
                        repository: context.read<FlashcardRepository>(),
                      )..add(LoadDecks()),
                      child: child!,
                    ),
                  );
                }
                return child!;
              },
            );
          },
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return const DeckListPage();
              }
              if (state is AuthLoading) {
                return const Scaffold(body: Center(child: Loader()));
              }
              return const LoginPage();
            },
          ),
        ),
      ),
    );
  }
}
