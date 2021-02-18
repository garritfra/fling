import 'package:fling/fling.dart';
import 'package:flutter/material.dart';
import 'package:fling/TodoModel.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FirebaseContainer());
}

class FirebaseContainer extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          print("Firebase connection state: ${snapshot.connectionState}");
          if (snapshot.connectionState == ConnectionState.done) {
            return ChangeNotifierProvider(
                create: (BuildContext context) => TodoModel(),
                child: FlingApp());
          } else {
            return Container(
              color: Colors.white,
            );
          }
        });
  }
}
