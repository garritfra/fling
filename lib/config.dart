import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

class ConfigPage extends StatefulWidget {
  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final storage = new LocalStorage("fling.json");
  List<String> _knownLists = ["myfirstlist"];
  String _currentList = "";

  final _nameTextController = TextEditingController();

  final _newListController = TextEditingController();

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
    _currentList = storage.getItem("list");
    if (_currentList == null) {
      _currentList = _knownLists.first;
    }

    final String listKey = "known_lists";

    _ensureKnownListsSet(listKey);

    var rawLists = storage.getItem("known_lists");

    List<dynamic> knownLists = json.decode(rawLists);

    if (knownLists == null) {
      setState(() {
        _knownLists = [];
      });
    } else {
      setState(() {
        _knownLists = knownLists.map((el) => el.toString()).toList();
      });
    }
  }

  void _ensureKnownListsSet(String listKey) {
    if (storage.getItem(listKey) == null) {
      storage.setItem(listKey, json.encode(['myfirstlist']));
    }
  }

  void _addListToKnown(String list) {
    var oldKnown = storage.getItem("known_lists");
    if (oldKnown == null) oldKnown = "[]";
    List<String> known =
        json.decode(oldKnown).map<String>((el) => el.toString()).toList();
    if (!known.contains(list)) known.add(list);
    storage.setItem("known_lists", json.encode(known));
    setState(() {
      _currentList = list;
      _knownLists = known;
    });
  }

  void _onSubmit() async {
    if (_nameTextController.text.isNotEmpty) {
      storage.setItem("name", _nameTextController.text);
    }
    storage.setItem("list", _currentList);
  }

  @override
  Widget build(BuildContext context) {
    _showAddListDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Liste hinzufügen"),
            content: Expanded(
              child: Container(
                child: TextField(
                  controller: _newListController,
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
              ),
            ),
            actions: [
              TextButton(
                  child: Text('Abbrechen'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
              TextButton(
                  child: Text('Hinzufügen'),
                  onPressed: () {
                    // Hier passiert etwas
                    Navigator.of(context).pop();
                    if (_newListController.text.isNotEmpty) {
                      _addListToKnown(_newListController.text);
                      _newListController.clear();
                    }
                  }),
            ],
          );
        },
      );
    }

    _buildAddListDialog() {
      return IconButton(
        icon: Icon(Icons.add),
        onPressed: _showAddListDialog,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Einstellungen"),
      ),
      body: Container(
        child: Center(
          child: SizedBox(
            width: 400,
            child: ListView(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(5.0),
                    child: TextField(
                      controller: _nameTextController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(), labelText: "Dein Name"),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                      padding: EdgeInsets.all(5.0),
                      child: Row(
                        children: [
                          DropdownButton<String>(
                            hint: Text("Liste"),
                            value: _currentList,
                            items: _knownLists
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              storage.setItem("list", value).then((_) {
                                setState(() {
                                  _currentList = value;
                                });
                              });
                            },
                          ),
                          _buildAddListDialog(),
                        ],
                      )),
                ),
                Container(
                  padding: EdgeInsets.all(5.0),
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
