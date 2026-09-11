import 'package:flutter/material.dart';
import 'package:flutter_application_230318/presentation/screens/counter/counter_functions_screen.dart';
import 'package:flutter_application_230318/presentation/screens/counter/counter_screen.dart';


void main(){
  runApp(MyApp());
  
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.brown
      ),
      home: CounterFunctionsScreen()
    );
  }
}