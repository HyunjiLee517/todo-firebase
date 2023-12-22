import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

FirebaseFirestore db = FirebaseFirestore.instance; //firebase instance

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Todo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade200),
        useMaterial3: true,
      ),
      home: const TodoList(title: 'Todo Manager'),
    );
  }
}

class TodoList extends StatefulWidget {
  const TodoList({super.key, required this.title});

  final String title;

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final TextEditingController _textFieldController = TextEditingController();

  void _addTodoItem(String name) {
    DocumentReference documentReference = db.collection("FirstTodos").doc(name);
    //Map
    Map<String, dynamic> todos = {
      "name": name,
      "completed": false,
    };
    documentReference.set(todos);
    _textFieldController.clear();
  }

  void _handleTodoChange(String name) {
    DocumentReference documentReference = db.collection("FirstTodos").doc(name);
    late bool initialValue;
    db
        .collection("FirstTodos")
        .where('name', isEqualTo: name)
        .get()
        .then((querysnapshot) => {
              if (querysnapshot.docs.isNotEmpty)
                {
                  initialValue = querysnapshot.docs.first.data()['completed'],
                  documentReference.update({'completed': !initialValue})
                }
            });
  }

  void _deleteTodo(String name) {
    DocumentReference documentReference = db.collection("FirstTodos").doc(name);
    documentReference.delete();
  }

  Future<void> _displayDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a todo.'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: 'Type your todo'),
            autofocus: true,
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              )),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              )),
              onPressed: () {
                Navigator.of(context).pop();
                _addTodoItem(_textFieldController.text);
              },
              child: const Text('Add'),
            )
          ],
        );
      },
    );
  }

  // Text? _emptybody() {
  //   if (_todos.isEmpty) return const Text('empty list');
  //   return null;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: db.collection("FirstTodos").snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text(
                'There is no todo. Add one to start',
                style: TextStyle(fontSize: 18),
              ));
            }
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> data =
                    document.data()! as Map<String, dynamic>;
                return TodoItem(
                  // todo: Todo todo,
                  todo: data,
                  onTodoChanged: _handleTodoChange,
                  removeTodo: _deleteTodo,
                );
              }).toList(),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayDialog(),
        tooltip: 'Add a Todo',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TodoItem extends StatelessWidget {
  TodoItem({
    required this.todo,
    required this.onTodoChanged,
    required this.removeTodo,
  }) : super(key: ObjectKey(todo));

  final Map<String, dynamic> todo;
  final void Function(String name) onTodoChanged;
  final void Function(String name) removeTodo;

  TextStyle? _getTextStyle(bool checked) {
    if (!checked) return null;

    return const TextStyle(
      color: Colors.black54,
      decoration: TextDecoration.lineThrough,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        onTodoChanged(todo['name']);
      },
      leading: Checkbox(
        checkColor: Colors.white,
        activeColor: Colors.green,
        value: todo['completed'],
        onChanged: (value) {
          onTodoChanged(todo['name']);
        },
      ),
      title: Row(children: <Widget>[
        Expanded(
          child: Text(
            todo['name'],
            style: _getTextStyle(todo['completed']),
          ),
        ),
        IconButton(
            iconSize: 30,
            alignment: Alignment.centerRight,
            onPressed: () {
              removeTodo(todo['name']);
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            )),
      ]),
    );
  }
}


/* return ListView(
          children: snapshot.data!.docs
              .map((DocumentSnapshot document) {
                Map<String, dynamic> data =
                    document.data()! as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['full_name']),
                  subtitle: Text(data['company']),
                );
              })
              .toList()
              .cast(),
        ); */