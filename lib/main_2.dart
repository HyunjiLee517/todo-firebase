import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

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
  final List<Todo> _todos = <Todo>[];
  final TextEditingController _textFieldController = TextEditingController();

  void _addTodoItem(String name) {
    setState(() {
      _todos.add(Todo(name: name, completed: false));
      _textFieldController.clear();
    });
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

  void _handleTodoChange(Todo todo) {
    setState(() {
      todo.completed = !todo.completed;
    });
  }

  void _deleteTodo(Todo todo) {
    setState(() {
      _todos.removeWhere((element) => element.name == todo.name);
    });
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
          stream:
              FirebaseFirestore.instance.collection("FirstTodos").snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: _todos.isEmpty
                  ? <Widget>[
                      const Center(
                        child: Text('No Todo Item. Add your todos here!'),
                      )
                    ]
                  : _todos.map((Todo todo) {
                      return TodoItem(
                        todo: todo,
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

class Todo {
  Todo({
    required this.name,
    required this.completed,
  });
  String name;
  bool completed;
}

class TodoItem extends StatelessWidget {
  TodoItem({
    required this.todo,
    required this.onTodoChanged,
    required this.removeTodo,
  }) : super(key: ObjectKey(todo));
  final Todo todo;
  final void Function(Todo todo) onTodoChanged;
  final void Function(Todo todo) removeTodo;
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
        onTodoChanged(todo);
      },
      leading: Checkbox(
        checkColor: Colors.white,
        activeColor: Colors.green,
        value: todo.completed,
        onChanged: (value) {
          onTodoChanged(todo);
        },
      ),
      title: Row(children: <Widget>[
        Expanded(
          child: Text(
            todo.name,
            style: _getTextStyle(todo.completed),
          ),
        ),
        IconButton(
            iconSize: 30,
            alignment: Alignment.centerRight,
            onPressed: () {
              removeTodo(todo);
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            )),
      ]),
    );
  }
}
