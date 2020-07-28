import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    title: "Lista de tarefas",
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _todoController = TextEditingController();

  List _todoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedIndex;

  @override
  void initState() {
    super.initState();
    _readData().then((value) {
      setState(() {
        _todoList = json.decode(value);
      });
    });
  }

  void _addTodo() {
    setState(() {
      final title = _todoController.text;
      _todoController.text = "";

      _todoList.add({"title": title, "ok": false});
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addTodo,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: EdgeInsets.only(top: 10),
              itemCount: _todoList.length,
              itemBuilder: buildItem,
            ),
          ))
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedIndex = index;
          _todoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved["title"]} removida"),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovedIndex, _lastRemoved);
                  _saveData();
                });
              },
            ),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
      child: CheckboxListTile(
        title: Text(_todoList[index]["title"]),
        value: _todoList[index]["ok"],
        onChanged: (value) {
          setState(() {
            _todoList[index]["ok"] = value;
            _saveData();
          });
        },
        secondary: CircleAvatar(
          child: _todoList[index]["ok"] ? Icon(Icons.check) : Icon(Icons.error),
        ),
      ),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"]) return 1;
        return 0;
      });
    });
  }
}
