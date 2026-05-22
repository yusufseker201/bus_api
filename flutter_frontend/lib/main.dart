import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'providers/session_state.dart';
import 'screens/auth_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const BusDensityApp());
}

class BusDensityApp extends StatelessWidget {
  const BusDensityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        ChangeNotifierProvider(
          create: (context) =>
              SessionState(context.read<AuthService>())..load(),
        ),
        ProxyProvider<SessionState, ApiService>(
          update: (_, session, __) =>
              ApiService(tokenProvider: () => session.token),
        ),
        ChangeNotifierProxyProvider2<ApiService, SessionState, AppState>(
          create: (context) => AppState(
            context.read<ApiService>(),
            context.read<SessionState>(),
          )..loadInitialData(),
          update: (context, api, session, state) {
            state ??= AppState(api, session);
            state.updateDependencies(api, session);
            return state;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kahramanmaraş Toplu Taşıma',
        theme: AppTheme.lightTheme(),
        home: const AuthGate(),
      ),
    );
  }
}
