import 'package:flutter/material.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => ObjectProvider(),
    child: MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    ),
  ));
}

@immutable
class BaseObject {
  final String id;
  final String lastUpdated;

  BaseObject()
      : id = const Uuid().v4(),
        lastUpdated = DateTime.now().toIso8601String();

  //his operator is useful when you need to compare actual values of two objects/classses followed by hashcode
  @override
  bool operator ==(covariant BaseObject other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class ExpensiveObject extends BaseObject {}

@immutable
class CheapObject extends BaseObject {}

//in this case we want multiple values to change, so we will use Change Notifier
class ObjectProvider extends ChangeNotifier {
  late String id;
  late CheapObject _cheapObject;
  late ExpensiveObject _expensiveObject;
  late StreamSubscription _cheapObjectSubs;
  late StreamSubscription _expensiveObjectSubs;

  CheapObject get cheapObject => _cheapObject; //getter
  ExpensiveObject get expensiveObject => _expensiveObject;

  //constructor to call ObjectProvider
  ObjectProvider()
      : id = const Uuid().v4(),
        _cheapObject = CheapObject(),
        _expensiveObject = ExpensiveObject() {
    start();
  }

  //whenever we call notifyListeners(), we will reset our "id" field
  @override
  void notifyListeners() {
    id = const Uuid().v4();
    super.notifyListeners();
  }

  //change main function to create provider

  void start() {
    //function that kicks in the stream
    _cheapObjectSubs = Stream.periodic(
      const Duration(seconds: 1),
    ).listen((_) {
      _cheapObject = CheapObject();
      notifyListeners();
    });

    _expensiveObjectSubs = Stream.periodic(
      const Duration(seconds: 10),
    ).listen((_) {
      _expensiveObject = ExpensiveObject();
      notifyListeners();
    });
  }

  void stop() {
    _cheapObjectSubs.cancel();
    _expensiveObjectSubs.cancel();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Column(
        children: [
          Row(
            children: const [
              Expanded(child: CheapWidget()),
              Expanded(child: ExpensiveWidget()),
            ],
          ),
          Row(
            children: const [
              Expanded(child: ObjectProviderWidget()),
            ],
          ),
          Row(
            children: [
              TextButton(
                  onPressed: (() {
                    context.read<ObjectProvider>().stop();
                  }),
                  child: const Text('Stop')),
              TextButton(
                onPressed: (() {
                context.read<ObjectProvider>().start();
                }), 
              child: const Text('Start')),
            ],
          )
        ],
      ),
    );
  }
}

class ExpensiveWidget extends StatelessWidget {
  const ExpensiveWidget({super.key});

  @override
  Widget build(BuildContext context) {
    //select depends on equality
    final expensiveObject = context.select<ObjectProvider, ExpensiveObject>(
      (provider) => provider.expensiveObject,
    );
    return Container(
        height: 100,
        color: Colors.red,
        child: Column(
          children: [
            const Text('Expensive Widget'),
            const Text('Last Updated'),
            Text(expensiveObject.lastUpdated),
            Text(expensiveObject.id),
          ],
        ));
  }
}

class CheapWidget extends StatelessWidget {
  const CheapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    //select depends on equality
    final cheapObject = context.select<ObjectProvider, CheapObject>(
      (provider) => provider.cheapObject,
    );
    return Container(
        height: 100,
        color: Colors.yellow,
        child: Column(
          children: [
            const Text('Cheap Widget'),
            const Text('Last Updated'),
            Text(cheapObject.lastUpdated),
            Text(cheapObject.id),
          ],
        ));
  }
}

class ObjectProviderWidget extends StatelessWidget {
  const ObjectProviderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    //select depends on equality
    final provider = context.watch<ObjectProvider>();
    return Container(
        height: 100,
        color: Colors.purple,
        child: Column(
          children: [
            const Text('ObjectProvider Widget'),
            const Text('ID'),
            Text(provider.id),
          ],
        ));
  }
}
