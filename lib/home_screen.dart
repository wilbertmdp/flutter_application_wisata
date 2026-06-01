import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_wisata/sign_in_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => SignInScreen()));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home Screen"),
       actions: [
        IconButton(onPressed: (){
          signOut(context);
        }, icon: Icon(Icons.logout))
       ], 
      ),
      body: Center(
        child: Text("Welcome!!!!"),
      ),
    );
  }
}