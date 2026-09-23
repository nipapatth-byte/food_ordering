import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/reservation_provider.dart';
import 'pages/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
      ],
      child: MaterialApp(
        title: 'กินไรดี (Kin Rai Dee)',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF4D26),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 70,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.black,
            indicatorColor: const Color(0xFF3A201B),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: Color(0xFFE6391A),
            unselectedItemColor: Color(0xFFB8AAA5),
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.w800),
            type: BottomNavigationBarType.fixed,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFF201D1B),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            hintStyle: TextStyle(color: Color(0xFF9B8C86)),
            prefixIconColor: Color(0xFFB8AAA5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xFF4B3A35), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xFF4B3A35), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xFFE6391A), width: 2),
            ),
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFFE6391A),
            contentTextStyle: TextStyle(color: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0321C),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 52),
              elevation: 3,
              shadowColor: const Color(0x66F0321C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF201D1B),
            elevation: 3,
            shadowColor: const Color(0x66000000),
            margin: EdgeInsets.zero,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              side: BorderSide(color: Color(0xFF3D302C)),
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: const Color(0xFF201D1B),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFF2A211F),
            selectedColor: const Color(0xFFF0321C),
            side: const BorderSide(color: Color(0xFF4B3A35)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          useMaterial3: true,
        ),
        // เข้ามาเจอ Home ทันที ไม่บังคับ login ก่อน (guest ดูเมนู/โต๊ะได้)
        home: const MainScaffold(),
      ),
    );
  }
}
