import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
//import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle;

class Dbs {
    //static Future<Database> database;
    Future<String> getFileData(String path) async {
      return await rootBundle.loadString(path);
    }
    void loadSongs() async{
      String read = await getFileData("assets/songs_init.txt");
      List<String> readIn = read.split('\n');
      for(int i=0;i<readIn.length;i++){
        List<String> readOne = readIn[i].split('*');
        String newLast = "";
        for(int j=0;j<readOne[readOne.length-1].length;j++){
          if(readOne[readOne.length-1][j] == '\r')
          break;
          newLast += readOne[readOne.length-1][j];
        }
        readOne[readOne.length-1] = newLast;
        String artists = readOne[0].split('-')[0];
        String names = readOne[0].split('-')[1];
        print(i.toString()+": " + artists +" and " + names);
        //insertSongs(new Song(id: i, name: names, artist: artists, urlSong: readOne[1], urlPic: readOne[2], category: readOne[3]));
          await Firebase.initializeApp();
          FirebaseFirestore.instance.collection('Songs').doc(i.toString()).set({'id': i, 'name': names, 'artist': artists, 'urlMusic': readOne[1], 'urlPicture': readOne[2], 'category': readOne[3]});
      }
    }
    void createCustomer(Customer customer) async{
      await Firebase.initializeApp();
      FirebaseFirestore.instance.collection('Customers').doc(customer.email).set({'email': customer.email, 'password': customer.password, 'name': customer.name, 'lastListened': customer.lastListened, 'liked': customer.liked, 'history': customer.history, 'playlists': customer.playlists});
    }
    void initialize() async {
      WidgetsFlutterBinding.ensureInitialized();
      //loadSongs();
    }
    Future<Customer> findCustomer(String email) async{
      DocumentReference doc = FirebaseFirestore.instance.collection("Customers").doc(email);
      var document = await doc.get();
       Customer retCustomer = new Customer(email: document.get('email'), password: document.get('password'), name: document.get('name'), lastListened: document.get('lastListened'), liked: document.get('liked'), history: document.get('history'), playlists: document.get('playlists'));
       return retCustomer;
    }
    void updateCustomerLiked(Customer customer, String liked) async {
      FirebaseFirestore.instance.collection("Customers").doc(customer.email).update({'liked': liked});
    }
    void updateCustomerHistory(Customer customer, String history) async {
      FirebaseFirestore.instance.collection("Customers").doc(customer.email).update({'history': history});
    }
    void updateCustomerLastListened(Customer customer, String lastListened) async {
      FirebaseFirestore.instance.collection("Customers").doc(customer.email).update({'lastListened': lastListened});
    }
    void updateCustomerPlaylist(Customer customer, String playlists) async {
      FirebaseFirestore.instance.collection("Customers").doc(customer.email).update({'playlists': playlists});
    }
    Future<void> deleteCustomer(Customer customer) async {
      FirebaseFirestore.instance.collection("Customers").doc(customer.email).delete();
    }
  }
class Customer {
  String name, email, password, lastListened, liked, history, playlists;
  Customer({this.name, this.email, this.password, this.lastListened, this.liked, this.history, this.playlists});
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'lastListened': lastListened,
      'liked': liked,
      'history': history,
      'playlists': playlists,
    };
  }
  @override
  String toString() {
    return 'Customer{name: $name, email: $email, password: $password, liked: $liked, history: $history, playlists: $playlists}';
  }
}
class SongCategory {
  int id;
  int occurrence;
  String name;
  SongCategory(int id, String name, int occurrence){
    this.id = id;
    this.name = name;
    this.occurrence = occurrence;
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'occurrence': occurrence,
    };
  }
}
class Song{
  final int id;
  String name, artist, urlSong, urlPic, category;
  Song({this.id, this.name, this.artist, this.urlSong, this.urlPic, this.category});
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'urlSong': urlSong,
      'urlPic': urlPic,
      'category': category,
    };
  }
  @override
  String toString() {
    return 'Song{id: $id, name: , artist: $artist, $name, category: $category, urlSong: $urlSong}';
  }
}