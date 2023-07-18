import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sig_grupL/screens/screens.dart';
import 'package:sig_grupL/services/ubi_services.dart';


void main() async {
  await dotenv.load(fileName: '.env');
  runApp(const AppState());
} 
class AppState extends StatelessWidget {
  const AppState({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => UbiService()),
      
    ], 
    child: const MyApp() 
    );
  }
}

class MyApp extends StatelessWidget {
  
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Universidad Taxi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Montserrat'),
        initialRoute: '/splash',
        routes: <String, WidgetBuilder>{
          '/home': (BuildContext context) => const Home(),
          '/splash': (BuildContext context) => const Splash(),
        });
  }
}
