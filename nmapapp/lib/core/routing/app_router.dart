import 'package:go_router/go_router.dart';
import '../../features/network_info/presentation/network_dashboard_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const NetworkDashboardScreen(),
      ),
    ],
  );
}
