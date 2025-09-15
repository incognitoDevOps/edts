import 'package:flutter/material.dart';
import 'routes.dart';
import 'package:moderntr/services/auth_service.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure errors don't cause silent failure in release
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Run app inside a protected zone
  runApp(await initializeApp());
}

Future<Widget> initializeApp() async {
  try {
    bool loggedIn = await AuthService().isLoggedIn();
    String initialRoute = loggedIn ? '/home' : '/splash'; // Change to your actual routes
    return MyApp(initialLocation: initialRoute);
  } catch (e, stackTrace) {
    print("🔥 Initialization error: $e");
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text("Something went wrong.\n$e")),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final String initialLocation;

  const MyApp({super.key, required this.initialLocation});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Modern Tr',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter(initialLocation),
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData.light(),
    );
  }
}
