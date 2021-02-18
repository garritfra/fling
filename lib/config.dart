import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

class ConfigPage extends StatefulWidget {
  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final storage = new LocalStorage("Fling");
  List<dynamic> _knownLists = ["myfirstlist"];
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

    List<dynamic> knownLists = json.decode(storage.getItem("known_lists"));
    if (knownLists == null) {
      setState(() {
        _knownLists = [];
      });
    } else {
      setState(() {
        _knownLists = knownLists;
      });
    }
  }

  void _addListToKnown(String list) {
    var oldKnown = storage.getItem("known_lists");
    if (oldKnown == null) oldKnown = "[]";
    List<dynamic> known = json.decode(oldKnown);
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
                          DropdownButton(
                            hint: Text("Liste"),
                            value: DropdownMenuItem(
                              child: Text(_knownLists
                                  .firstWhere((item) => item == _currentList)),
                            ),
                            items: _knownLists
                                .map(
                                    (lst) => DropdownMenuItem(child: Text(lst)))
                                .toList(),
                            onChanged: (value) {
                              storage.setItem("list", value);
                            },
                          ),
                          Expanded(
                            child: Container(
                              child: TextField(
                                controller: _newListController,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder()),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              if (_newListController.text.isNotEmpty) {
                                _addListToKnown(_newListController.text);
                              }
                            },
                          )
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
