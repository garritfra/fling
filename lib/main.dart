import 'package:firebase_core/firebase_core.dart';
import 'package:fling/model/shopping_list.dart';
import 'package:fling/ui/fling.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                create: (BuildContext context) => TodoListModel(),
                child: FlingApp());
          } else {
            return Container(
              color: Colors.white,
            );
          }
        });
  }
}
