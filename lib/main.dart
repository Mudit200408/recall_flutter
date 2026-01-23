import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:recall/features/auth/presentation/pages/login_page.dart';
import 'package:recall/features/recall/data/repositories/flashcard_repository_impl.dart';
import 'package:recall/features/recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/features/recall/presentation/bloc/deck/deck_bloc.dart';
import 'package:recall/features/recall/presentation/pages/deck_page.dart';
import 'package:recall/firebase_options.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.init();
  final aiModel = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash',
    generationConfig: GenerationConfig(responseMimeType: 'application/json'),
  );

  // final repo = FlashcardRepositoryImpl(
  //   firestore: FirebaseFirestore.instance,
  //   aiModel: model, userId: '',
  // );

  runApp(MainApp(aiModel: aiModel));
}

class MainApp extends StatelessWidget {
  final GenerativeModel aiModel;
  const MainApp({super.key, required this.aiModel});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
      ],
      child:  BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if(state is AuthAuthenticated) {
             return RepositoryProvider<FlashcardRepository>(
                  create: (context) => FlashcardRepositoryImpl(
                    firestore: di.sl(),
                    aiModel: aiModel,
                    userId: state.user.uid,
                  ),
                  child: BlocProvider(
                    create: (context) => DeckBloc(
                      repository: context.read<FlashcardRepository>(),
                    )..add(LoadDecks()),
                    child: MaterialApp(
                      theme: theme,
                      home: const DeckListPage(),
                    ),
                  ),
                );
            }

            return MaterialApp(
              theme: theme,
              home: state is AuthLoading ? const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ) : const LoginPage(),
            );
          },
        ),
    
    );
  }
}
