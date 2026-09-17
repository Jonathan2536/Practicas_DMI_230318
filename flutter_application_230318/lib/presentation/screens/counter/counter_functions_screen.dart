import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Pantalla de contador con varias acciones: sumar, restar y reiniciar.
class CounterFunctionsScreen extends StatefulWidget {
  const CounterFunctionsScreen({super.key});

  @override
  State<CounterFunctionsScreen> createState() => _CounterFunctionsScreenState();
}

class _CounterFunctionsScreenState extends State<CounterFunctionsScreen> {
  // Guarda el número actual que se muestra en pantalla.
  int clickCounter = 0;

  // Texto adicional que se muestra debajo del contador.
  String click = " ";

  @override
  Widget build(BuildContext context) {
    // El color cambia según el valor del contador.
    Color numeroColor = Colors.blue; 
    if (clickCounter > 0) {
      numeroColor = Colors.green;
    } else if (clickCounter < 0) {
      numeroColor = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter Functions'),
        centerTitle: true,
        actions: [
          // Reinicia el contador y limpia el texto desde la barra superior.
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                clickCounter = 0;
                click = " ";
              });
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Muestra el valor actual con un tamaño grande.
            Text(
              '$clickCounter',
              style: GoogleFonts.openSans(
                fontSize: 160,
                color: numeroColor,
              ),
            ),
            // Muestra el texto adicional debajo del número.
            Text(
              '$click', 
              style: GoogleFonts.openSans(fontSize: 40)
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón para volver el contador a cero.
          CustomButton( icon: Icons.refresh_rounded,
            onPressed: () {
              clickCounter=0;
              setState(() {
                
              });
            },),
          const SizedBox(height: 10),
          // Botón para disminuir el contador en una unidad.
          CustomButton( icon: Icons.exposure_minus_1_outlined,
            onPressed: () {
              clickCounter--;
              setState(() {
                
              });
            },),
          const SizedBox(height: 10),
          // Botón para aumentar el contador en una unidad.
          CustomButton( icon: Icons.plus_one,
            onPressed: () {
              clickCounter++;
              setState(() {
                
              });
            },),
          
        ],
      ),
    );
  }
}

// Botón reutilizable que recibe un icono y la acción que debe realizar.
class CustomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const CustomButton({
    super.key, 
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      // shape: const StadiumBorder(),
      enableFeedback: true,
      elevation: 20,
      onPressed: onPressed,
      child:  Icon(icon),
    );
  }
}