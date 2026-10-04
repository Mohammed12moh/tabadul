import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth_screen.dart';
import '../../features/chat_screen.dart';
import '../../features/home_screen.dart';
import '../../features/listing_screen.dart';
import '../../features/profile_screen.dart';

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRouter {
  AppRouter._();

  static GoRouter create() {
    final auth = Supabase.instance.client.auth;
    return GoRouter(
      initialLocation: '/',
      refreshListenable: _AuthRefresh(auth.onAuthStateChange),
      redirect: (context, state) {
        final loggedIn = auth.currentSession != null;
        final atAuth = state.matchedLocation == '/auth';
        if (!loggedIn && !atAuth) return '/auth';
        if (loggedIn && atAuth) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/add', builder: (_, __) => const AddListingScreen()),
        GoRoute(
          path: '/listing/:id',
          builder: (_, s) => ListingDetailScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/chat/:listingId',
          builder: (_, s) =>
              ChatScreen(listingId: s.pathParameters['listingId']!),
        ),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    );
  }
}
