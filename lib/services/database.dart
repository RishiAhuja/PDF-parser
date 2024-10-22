import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  uploadUserInfo(Map<String, String> map, String uid) async {
    // FirebaseFirestore.instance.collection("users").add(map);
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    await users.doc(uid).set(map).then((_) {
      print("User added with ID: $uid");
    }).catchError((error) {
      print("Failed to add user: $error");
    });
  }

  addPdfData(Map<String, dynamic> map, String uid) async {
    // FirebaseFirestore.instance.collection("users").add(map);
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    await users.doc(uid).collection("pdf").add(map).then((_) {
      print("pdf added with ID: $uid");
    }).catchError((error) {
      print("Failed to add pdf: $error");
    });
  }
}
