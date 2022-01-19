import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

class ConfigPage extends StatefulWidget {
  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final storage = new LocalStorage("fling.json");

  final _nameTextController = TextEditingController();
  final _householdTextController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    _init();
    super.initState();
  }

  Future _init() async {
    await storage.ready;

    String name = storage.getItem("name");
    if (name != null) {
      _nameTextController.text = name;
    }

    String household = storage.getItem("household");
    if (household != null) {
      _householdTextController.text = household;
    }
  }

  void _onSubmit() async {
    if (_nameTextController.text.isNotEmpty) {
      storage.setItem("name", _nameTextController.text);
    }
    if (_householdTextController.text.isNotEmpty) {
      storage.setItem("household", _householdTextController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Einstellungen"),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: 400,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        child: TextField(
                          controller: _nameTextController,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Dein Name"),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        child: TextField(
                          controller: _householdTextController,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Haushalt"),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  child: ElevatedButton(
                    onPressed: _onSubmit,
                    child: Text("Save"),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
