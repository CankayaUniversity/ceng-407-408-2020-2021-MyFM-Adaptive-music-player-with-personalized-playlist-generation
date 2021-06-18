import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:provider/provider.dart';
import 'AuthenticationServices.dart';
import 'Customer.dart';
import 'main.dart';
final Dbs d = new Dbs();
class Register extends StatelessWidget {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text("Register an Account"),
        centerTitle: true,
        backgroundColor: color,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              child: TextField(controller: email,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                    hintText: "Enter Email..."),
              ),
            ),
            Container(
              child: TextField(controller: name,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                    hintText: "Enter Username(optional)..."),
              ),
            ),
            Container(
              child: TextField(controller: password,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                    hintText: "Enter Password..."),
              ),
            ),
            Container(
              child: ElevatedButton(style: ElevatedButton.styleFrom(primary: color),onPressed: () async{
                if(email.text == "" || password.text == "") {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter all fields.")));
                  return;
                }
                email.text = email.text.trim();
                password.text = password.text.trim();
                String result = await context.read<AuthenticationServices>().signUp(
                  email: email.text.trim(),
                  password: password.text.trim(),
                );
                if(result == "Signed up") {
                  Customer newCustomer = new Customer(
                    name: this.name.text == null ? "" : this.name.text,
                    email: this.email.text.toLowerCase(),
                    password: this.password.text,
                    playlists: "",
                    history: "",
                    liked: "",
                  );
                  d.createCustomer(newCustomer);
                  playlistNames = new List<String>.empty(growable: true);
                  playListChange = true;
                  page = 0;
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => WelcomeSend(newCustomer, null)));
                  Phoenix.rebirth(context);
                }
                else
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
              },
                child: new Text("Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}