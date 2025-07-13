import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';

void main() {
  // Ensure Flutter is initialized before accessing plugins
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Food App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color(0xFFFC8019),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFC8019),
              primary: const Color(0xFFFC8019),
            ),
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
          ),
          home: FutureBuilder(
            future: auth.autoLogin(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.data == true) {
                return const HomePage();
              }

              return const LoginPage();
            },
          ),
        ),
      ),
    );
  }
}
