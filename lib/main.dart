import 'package:flutter/material.dart';
import 'package:lista_tarefas/models/task_model.dart';
import 'dart:async';
import 'components/api_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Api Task Service',
        theme: ThemeData(
          useMaterial3: true,
        ),
        home: const TodoScreen());
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({Key? key}) : super(key: key);

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  TextEditingController taskController = TextEditingController();
  List<Task> tasks = []; // Lista para armazenar as tarefas
  List<Task> completedTasks = []; //Lista para armazenar tarefas completadas
  ApiService apiService = ApiService(); // Instância do ApiService

  @override
  void initState() {
    super.initState();
    _fetchTasks(); // Busca tarefas ao iniciar a tela
  }

  Future<void> _fetchTasks() async {
    try {
      List<Task> fetchedTasks = await apiService.fetchTasks();
      setState(() {
        tasks = fetchedTasks;
      });
    } catch (e) {}
  }

  Future<void> _addTask() async {
    String newTaskTitle = taskController.text;
    if (newTaskTitle.isNotEmpty) {
      Task newTask = Task(
        id: tasks.length + 1,
        title: newTaskTitle, // Adiciona uma Tarefa e retorna
      );

      try {
        Task addedTask = await apiService.addTask(newTask);
        setState(() {
          tasks.add(addedTask);
        });
      } catch (e) {}
    }
    taskController.clear();
  }

//Lógica PUT de Tarefas:
  void updateTaskList(Task updatedTask) {
    setState(() {
      if (tasks.any((t) => t.id == updatedTask.id)) {
        tasks[tasks.indexWhere((t) => t.id == updatedTask.id)] = updatedTask;
      } else {
        tasks.add(updatedTask);
      }
    });
  }

  Future<void> editTaskText(Task task) async {
    TextEditingController editingController = TextEditingController();
    editingController.text = task.title;

    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Tarefa'),
          content: TextField(
            controller: editingController,
            decoration: const InputDecoration(
              hintText: 'Novo texto da tarefa',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancela a edição
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirma a edição
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    //Função que define se após a confirmação o item será editado ou não
    if (confirmed != null && confirmed) {
      String editedText = editingController.text;
      Task editedTask =
          Task(id: task.id, title: editedText, isCompleted: task.isCompleted);

      try {
        await apiService.updateTask(editedTask);
        updateTaskList(editedTask);
      } catch (e) {}
    }
  }

//Lógica DELETE de Tarefas:
  Future<void> _confirmDeleteTask(Task task) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Tarefa'),
          content:
              Text('Tem certeza que deseja excluir a tarefa "${task.title}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
    //Função que confirma se o item será excluído ou não
    if (confirmDelete != null && confirmDelete) {
      try {
        await apiService.deleteTask(task.id);
        setState(() {
          tasks.remove(task);
        });
      } catch (e) {
        print('Erro ao excluir tarefa');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade600,
        title: const Text(
          'Lista de Tarefas',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(30)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: taskController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            hintText: 'Digite a nova tarefa...',
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addTask,
                  ),
                ],
              ),
            ),
            const Text("Tarefas"),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  Task task = tasks[index];
                  return Dismissible(
                    key: Key(task.id.toString()),
                    background: Container(color: Colors.red),
                    onDismissed: (_) {
                      _confirmDeleteTask(task);
                    },
                    child: ListTile(
                      title: Text(
                        task.title,
                        style: task.isCompleted
                            ? const TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                                decoration: TextDecoration.lineThrough)
                            : null,
                      ),
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (bool? newValue) {
                          setState(() {
                            if (newValue!) {
                              // Se marcado como concluído, move da lista de tarefas para a de concluídas
                              tasks.remove(task);
                              completedTasks.add(task);
                            } else {
                              // Se desmarcado, move da lista de concluídas para a de tarefas
                              completedTasks.remove(task);
                              tasks.add(task);
                            }
                            task.isCompleted = newValue;
                          });
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: Colors.orange,
                            onPressed: () {
                              editTaskText(task);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () {
                              _confirmDeleteTask(task);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text("Tarefas Completadas"),
            Expanded(
                child: ListView.builder(
                    itemCount: completedTasks.length,
                    itemBuilder: (context, index) {
                      Task task = completedTasks[index];
                      return ListTile(
                        title: Text(
                          task.title,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (bool? newValue) {
                            setState(() {
                              if (newValue!) {
                                completedTasks.add(task);
                                tasks.remove(task);
                              } else {
                                tasks.add(task);
                                completedTasks.remove(task);
                              }
                              task.isCompleted = newValue;
                            });
                          },
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () {
                            _confirmDeleteTask(task);
                          },
                        ),
                      );
                    }))
          ],
        ),
      ),
    );
  }
}
