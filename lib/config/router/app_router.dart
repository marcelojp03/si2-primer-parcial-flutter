import 'package:go_router/go_router.dart';
import 'package:si2_p1_mobile/features/auth/screens/login_screen.dart';
import 'package:si2_p1_mobile/features/auth/screens/register_screen.dart';
import 'package:si2_p1_mobile/features/home/screens/home_screen.dart';
import 'package:si2_p1_mobile/features/incidents/screens/new_incident_screen.dart';
import 'package:si2_p1_mobile/features/incidents/screens/incident_tracking_screen.dart';
import 'package:si2_p1_mobile/features/incidents/screens/incident_history_screen.dart';
import 'package:si2_p1_mobile/features/incidents/screens/rating_screen.dart';
import 'package:si2_p1_mobile/features/vehicles/screens/vehicle_list_screen.dart';
import 'package:si2_p1_mobile/features/payments/screens/payment_screen.dart';
import 'package:si2_p1_mobile/features/payments/screens/qr_payment_screen.dart';
import 'package:si2_p1_mobile/features/profile/screens/profile_screen.dart';
import 'package:si2_p1_mobile/features/splash/screens/splash_screen.dart';
import 'package:si2_p1_mobile/features/technician/screens/technician_home_screen.dart';
import 'package:si2_p1_mobile/features/technician/screens/technician_assignment_screen.dart';
import 'package:si2_p1_mobile/config/layout/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: SplashScreen.name,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: LoginScreen.name,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: RegisterScreen.name,
      builder: (context, state) => const RegisterScreen(),
    ),

    // Shell con bottom nav (Home / Vehículos / Historial / Perfil)
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: HomeScreen.name,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/vehicles',
          name: VehicleListScreen.name,
          builder: (context, state) => const VehicleListScreen(),
        ),
        GoRoute(
          path: '/history',
          name: IncidentHistoryScreen.name,
          builder: (context, state) => const IncidentHistoryScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: ProfileScreen.name,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // Pantallas de técnico
    GoRoute(
      path: '/technician/home',
      name: TechnicianHomeScreen.name,
      builder: (context, state) => const TechnicianHomeScreen(),
    ),
    GoRoute(
      path: '/technician/assignment/:assignmentId',
      name: TechnicianAssignmentScreen.name,
      builder: (context, state) {
        final assignmentId = int.parse(state.pathParameters['assignmentId']!);
        final incidentId = int.tryParse(state.uri.queryParameters['incidentId'] ?? '') ?? assignmentId;
        return TechnicianAssignmentScreen(assignmentId: assignmentId, incidentId: incidentId);
      },
    ),

    // Pantallas fuera del shell
    GoRoute(
      path: '/incidents/new',
      name: NewIncidentScreen.name,
      builder: (context, state) => const NewIncidentScreen(),
    ),
    GoRoute(
      path: '/incidents/:id/tracking',
      name: IncidentTrackingScreen.name,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return IncidentTrackingScreen(incidentId: id);
      },
    ),
    GoRoute(
      path: '/incidents/:id/payment',
      name: PaymentScreen.name,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PaymentScreen(incidentId: id);
      },
    ),
    GoRoute(
      path: '/incidents/:id/qr-payment/:paymentId',
      name: QrPaymentScreen.name,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final paymentId = int.parse(state.pathParameters['paymentId']!);
        return QrPaymentScreen(incidentId: id, paymentId: paymentId);
      },
    ),
    GoRoute(
      path: '/incidents/:id/rating/:assignmentId',
      name: RatingScreen.name,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final assignmentId = int.parse(state.pathParameters['assignmentId']!);
        return RatingScreen(incidentId: id, serviceAssignmentId: assignmentId);
      },
    ),
  ],
);
