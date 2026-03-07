import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/fuel_log_detail_screen.dart';
import '../../presentation/screens/fuel_log_form_screen.dart';
import '../../presentation/screens/fuel_log_list_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/register_screen.dart';
import '../../presentation/screens/service_log_detail_screen.dart';
import '../../presentation/screens/service_log_form_screen.dart';
import '../../presentation/screens/service_log_list_screen.dart';
import '../../presentation/screens/reminder_detail_screen.dart';
import '../../presentation/screens/reminder_form_screen.dart';
import '../../presentation/screens/reminder_list_screen.dart';
import '../../presentation/screens/vehicle_list_screen.dart';
import '../../presentation/screens/vehicle_detail_screen.dart';
import '../../presentation/screens/vehicle_form_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isVehicleRoute = state.matchedLocation.startsWith('/vehicles');

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/vehicles';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/vehicles',
        builder: (context, state) => const VehicleListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return VehicleDetailScreen(id: id);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return VehicleFormScreen(id: id);
                },
              ),
              GoRoute(
                path: 'fuel-logs',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return FuelLogListScreen(vehicleId: id);
                },
                routes: [
                  GoRoute(
                    path: ':logId',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      final logId = state.pathParameters['logId']!;
                      return FuelLogDetailScreen(vehicleId: id, id: logId);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          final logId = state.pathParameters['logId']!;
                          return FuelLogFormScreen(vehicleId: id, id: logId);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'new',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return FuelLogFormScreen(vehicleId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'service-logs',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ServiceLogListScreen(vehicleId: id);
                },
                routes: [
                  GoRoute(
                    path: ':logId',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      final logId = state.pathParameters['logId']!;
                      return ServiceLogDetailScreen(vehicleId: id, id: logId);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          final logId = state.pathParameters['logId']!;
                          return ServiceLogFormScreen(vehicleId: id, id: logId);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'new',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ServiceLogFormScreen(vehicleId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'reminders',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ReminderListScreen(vehicleId: id);
                },
                routes: [
                  GoRoute(
                    path: ':reminderId',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      final reminderId = state.pathParameters['reminderId']!;
                      return ReminderDetailScreen(vehicleId: id, id: reminderId);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          final reminderId = state.pathParameters['reminderId']!;
                          return ReminderFormScreen(vehicleId: id, id: reminderId);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'new',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ReminderFormScreen(vehicleId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'new',
            builder: (context, state) => const VehicleFormScreen(),
          ),
        ],
      ),
    ],
  );
});