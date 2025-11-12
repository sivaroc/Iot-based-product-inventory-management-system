import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'services/firebase_service.dart';
import 'screens/landing_screen.dart';
import 'screens/rfid_monitor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Starting IoT Inventory App...');
  
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      debugPrint('🔥 Initializing Firebase...');
      await Firebase.initializeApp(
        options: FirebaseService.config,
      );
      debugPrint('✅ Firebase initialized successfully!');
      
      // Give Firebase a moment to fully initialize
      await Future.delayed(const Duration(milliseconds: 500));
    } else {
      debugPrint('⚠️ Firebase already initialized');
    }

    // Initialize Firebase Database
    await FirebaseService.initialize();
    debugPrint('✅ Firebase Database ready!');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
    debugPrint('⚠️ App will continue without Firebase - some features may not work');
    // Continue anyway - app can work without Firebase initially
  }

  debugPrint('🚀 Launching app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set preferred orientations to portrait only for better mobile experience
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return ScreenUtilInit(
      designSize: const Size(360, 800), // Common mobile screen size for reference
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'IoT Inventory System',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            textTheme: TextTheme(
              displayLarge: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              displayMedium: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
              bodyLarge: TextStyle(fontSize: 16.sp, height: 1.5),
              bodyMedium: TextStyle(fontSize: 14.sp, height: 1.5),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
                textStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            cardTheme: ThemeData.light().cardTheme.copyWith(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              margin: EdgeInsets.all(8.w),
            ),
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)), // Prevent text scaling
              child: child!,
            );
          },
          home: const LandingScreen(),
          routes: {
            '/rfid-monitor': (context) => const RFIDMonitorScreen(),
          },
        );
      },
    );
  }
}