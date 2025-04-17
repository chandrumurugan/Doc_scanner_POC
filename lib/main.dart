import 'package:doc_sacnner_poc/provider/camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:doc_sacnner_poc/screens/camera_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CameraProvider()..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Doc scanner poc',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const CameraScreen(),
      ),
    );
  }
}