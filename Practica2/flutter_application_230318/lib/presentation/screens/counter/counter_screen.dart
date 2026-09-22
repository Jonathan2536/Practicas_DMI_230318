import 'package:flutter/material.dart';

// Pantalla sencilla que aumenta un contador cada vez que se pulsa el botón.
class CounterScreen extends StatefulWidget {

  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}
class _CounterScreenState extends State<CounterScreen> {
  // Guarda el número de pulsaciones realizadas.
  int clickCounter = 0;

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Counter Screen'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:  [
          // Muestra el valor actual del contador.
          Text('$clickCounter',
           style: const TextStyle(fontSize: 160, fontWeight: FontWeight.w100),),
          // Texto que indica qué representa el número.
          const Text('Clicks', style: TextStyle(fontSize: 25 )),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        // setState actualiza la pantalla después de aumentar el contador.
        setState(() {
          clickCounter++;
        });
      },
      child: const Icon(Icons.plus_one),
    ),
  );
}
}