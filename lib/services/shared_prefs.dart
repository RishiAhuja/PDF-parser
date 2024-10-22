import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefMethods {
  Future<bool> setLogStatus(bool logStatus) async {
    SharedPreferences saveLogStatus = await SharedPreferences.getInstance();
    return await saveLogStatus.setBool("log", logStatus);
  }

  Future<bool> setName(String name) async {
    SharedPreferences saveName = await SharedPreferences.getInstance();
    return await saveName.setString("name", name);
  }

  Future<bool> setEmail(String email) async {
    SharedPreferences saveEmail = await SharedPreferences.getInstance();
    return await saveEmail.setString("email", email);
  }

  Future<bool> setUID(String email) async {
    SharedPreferences saveEmail = await SharedPreferences.getInstance();
    return await saveEmail.setString("uid", email);
  }

  Future<bool?> getLogStatus() async {
    SharedPreferences saveLogStatus = await SharedPreferences.getInstance();
    return saveLogStatus.getBool("log");
  }

  Future<String?> getName() async {
    SharedPreferences saveName = await SharedPreferences.getInstance();
    return saveName.getString("name");
  }

  Future<String?> getEmail() async {
    SharedPreferences saveEmail = await SharedPreferences.getInstance();
    return saveEmail.getString("email");
  }

  Future<String?> getUID() async {
    SharedPreferences saveEmail = await SharedPreferences.getInstance();
    return saveEmail.getString("uid");
  }
}
