import 'package:flutter/material.dart';

class CounterFunctionsScreen extends StatefulWidget {
  const CounterFunctionsScreen({super.key});

  @override
  State<CounterFunctionsScreen> createState() => _CounterFunctionsScreenState();
}




class _CounterFunctionsScreenState extends State<CounterFunctionsScreen> {
  int clickCounter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter functions'),
        actions: [
           IconButton(onPressed: () {

            setState(() {
              clickCounter = 0;
            }); 

         }, icon: const Icon(Icons.refresh_rounded,)),
        



        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$clickCounter',
              style: const TextStyle(
                fontSize: 160,
                fontWeight: FontWeight.w100,
              ),
            ),
            Text(
              'Click${clickCounter == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 25,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
        onPressed: () {
          setState(() {
            clickCounter++;
          });
        },
        child: const Icon(Icons.audiotrack_rounded),
      ),
      SizedBox(height: 20,),


          FloatingActionButton(
        onPressed: () {
          setState(() {
            clickCounter--;
          });
        },
        child: const Icon(Icons.exposure_minus_1_outlined),
      ),
          ],

      )
    );
  }
}