import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config.dart';
import 'services/backend.dart';
import 'services/demo/demo_backend.dart';
import 'services/firebase/firebase_backend.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FitLifeBackend backend;
  if (useFirebase) {
    // На Android/iOS потрібні google-services.json / GoogleService-Info.plist
    // (див. README, крок «Підключення Firebase»).
    await Firebase.initializeApp();
    backend = FirebaseBackend();
  } else {
    backend = DemoBackend();
  }
  final state = AppState(backend);
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const FitLifeApp(),
    ),
  );
  await state.init();
}
