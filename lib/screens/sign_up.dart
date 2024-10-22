import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf_parser/constants/constants.dart';
import 'package:pdf_parser/screens/dashboard.dart';
import 'package:pdf_parser/services/auth.dart';
import 'package:pdf_parser/services/database.dart';
import 'package:pdf_parser/services/shared_prefs.dart';
import 'package:sizer/sizer.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final AuthMethods _auth = AuthMethods();
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  final SharedPrefMethods _pref = SharedPrefMethods();
  final formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(221, 0, 0, 0),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Sign Up",
                    style:
                        GoogleFonts.dmMono(color: Colors.white, fontSize: 30),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: (Device.orientation == Orientation.portrait)
                        ? MediaQuery.of(context).size.width
                        : MediaQuery.of(context).size.width / 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 41, 41, 41),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Form(
                        key: formKey,
                        child: Container(
                          color: const Color.fromARGB(255, 41, 41, 41),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.person_2,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: TextFormField(
                                        style: GoogleFonts.archivo(
                                            color: Colors.white),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your name';
                                          } else if (value.length < 3) {
                                            return 'Name must be at least 3 characters long';
                                          } else if (value.contains(" ")) {
                                            return 'Spaces are not allowed';
                                          }
                                          return null;
                                        },
                                        controller: nameController,
                                        obscureText: false,
                                        cursorColor: const Color(0xFF2542A3),
                                        decoration: InputDecoration(
                                          hintText: "Name",
                                          hintStyle: GoogleFonts.archivo(),
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                        )),
                                  ),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.email,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: TextFormField(
                                        style: GoogleFonts.archivo(
                                            color: Colors.white),
                                        validator: (value) {
                                          String pattern =
                                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                                          RegExp regex = RegExp(pattern);
                                          return regex.hasMatch(value!)
                                              ? null
                                              : "Provide an valid email";
                                        },
                                        controller: emailController,
                                        cursorColor: const Color(0xFF2542A3),
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          hintText: "Email",
                                          hintStyle: GoogleFonts.archivo(),
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                        )),
                                  ),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.password,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: TextFormField(
                                        style: GoogleFonts.archivo(
                                            color: Colors.white),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a password';
                                          } else if (value.length < 6) {
                                            return 'Password must be at least 6 characters long';
                                          }
                                          return null;
                                        },
                                        controller: passwordController,
                                        cursorColor: const Color(0xFF2542A3),
                                        obscureText: true,
                                        decoration: InputDecoration(
                                          hintText: "Password",
                                          hintStyle: GoogleFonts.archivo(),
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                        )),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  InkWell(
                    onTap: () {
                      String name = nameController.text.trim();
                      String email = emailController.text.trim();
                      String password = passwordController.text.trim();

                      if (formKey.currentState!.validate()) {
                        _signUp(email, password, name);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 25),
                      alignment: Alignment.center,
                      width: (Device.orientation == Orientation.portrait)
                          ? MediaQuery.of(context).size.width
                          : MediaQuery.of(context).size.width / 3.3,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: const Color(0xFF2542A3),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        "Create account",
                        style: GoogleFonts.archivo(
                            color: Colors.white, fontSize: 14.sp),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _signUp(String email, String password, String name) async {
    setState(() {
      isLoading = true;
    });

    await _auth.signUpWithEmailAndPassword(email, password).then((val) {
      _pref.setLogStatus(true);
      _pref.setEmail(email);
      _pref.setName(name);
      _pref.setUID(val!.uid);

      Map<String, String> userInfo = {
        "name": name,
        "email": email,
        "password": password,
        "uid": val.uid
      };
      _databaseMethods.uploadUserInfo(userInfo, val.uid);

      Constants.localUsername = name;
      Constants.localEmail = email;
      Constants.localUID = val.uid;
      print("email: ${val.email}");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Dashboard()));
    }).catchError((e) {
      print(e);
    });
  }
}
