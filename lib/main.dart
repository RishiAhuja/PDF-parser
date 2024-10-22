import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_gemini/google_gemini.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pdf_parser/constants/constants.dart';
import 'package:pdf_parser/screens/dashboard.dart';
import 'package:pdf_parser/screens/log_in.dart';
import 'package:pdf_parser/screens/query_screen.dart';
import 'package:pdf_parser/screens/sign_up.dart';
import 'package:pdf_parser/services/auth.dart';
import 'package:pdf_parser/services/shared_prefs.dart';
import 'package:pdf_parser/widgets/front_button.dart';
import 'package:pdf_parser/widgets/navbar_button.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensures that plugin services are initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

bool isLoggedIn = false;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
            title: 'PDF parser',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: const AnonPage());
      },
    );
  }
}

class AnonPage extends StatefulWidget {
  const AnonPage({super.key});
  @override
  State<AnonPage> createState() => _AnonPageState();
}

class _AnonPageState extends State<AnonPage> {
  final gemini = GoogleGemini(
    apiKey: Constants.geminiApiKey,
  );

  String? responseByGemini;
  List questionsList = [];
  bool isLoading = false;
  String loadingText = "Trying to extract data from the PDF";
  String? extractedText;
  Uint8List? pickedBytes;

  final SharedPrefMethods _prefs = SharedPrefMethods();
  final AuthMethods _auth = AuthMethods();

  @override
  void initState() {
    getLogStatus(context);
    getUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: isLoading
          ? Center(
              child: Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(),
                  ),
                  Expanded(
                    flex: 10,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.black),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          loadingText,
                          style: GoogleFonts.archivo(
                              color: Colors.black87, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      // height: 80,
                      color: Colors.black87,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const NavbarButton(
                            text: "PDF Parser",
                            color: Colors.black,
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const SignUp())),
                                child: const NavbarButton(
                                  text: "Sign Up",
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const LogIn())),
                                child: const NavbarButton(
                                  text: "Login",
                                  color: Color(0xFF2542A3),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    )),
                Expanded(
                  flex: 10,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/background.webp"),
                        fit: BoxFit
                            .cover, // Ensures the image covers the entire container
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "Decode Your Documents",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.archivo(
                              color: Colors.white,
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Upload, Analyze, and Extract Knowledge instantly!",
                            style: GoogleFonts.archivo(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // FrontWidget(
                              //     text: "Upload Document",
                              //     onPressed: () => pickPDF(context),
                              //     iconData: Icons.arrow_forward),
                              FrontWidget(
                                  text: "Upload Document",
                                  //                   onPressed: () => Navigator.push(
                                  //                       context,
                                  //                       MaterialPageRoute(
                                  //                           builder: (context) =>
                                  //                               const QueryScreen(questions: [
                                  //                                 "How does asynchronous data transmission impact the efficiency of data transfer and processing?",
                                  //                                 "Explain the differences between synchronous and asynchronous transmission in terms of data framing and timing.",
                                  //                                 "Discuss the advantages and disadvantages of using asynchronous data streams in applications.",
                                  //                                 "How does the concept of futures in Dart facilitate the handling of asynchronous data?",
                                  //                                 "In what ways can the analogy of a restaurant waiter help us understand the concept of asynchronous data?",
                                  //                               ], extractedText: '''
                                  // Asynchronous data, streams, and futures:
                                  // Think of a busy restaurant where the waiter takes your order and then goes to serve other tables while your food is being prepared. You don't have to wait for your meal to be ready before the waiter can take other orders. This is exactly asynchronous data. Just like the waiter can serve multiple tables, asynchronous data allows a computer or application to handle several tasks at once.
                                  // Now let's understand the technicalities:
                                  // In asynchronous transmission, each character or byte of data is framed with a start bit and a stop bit. The start bit signals the beginning of the data transmission, while the stop bit indicates its end. For example, when sending an ASCII character, it might be represented as 10 bits: 1 start bit + 8 data bits + 1 stop bit.
                                  // This is cool, but it increases the memory that needs to be transferred because of the extra start and stop bits. And for the same reason, it also increases the processing overhead.
                                  // Data is sent one character at a time, as opposed to blocks or frames used in synchronous transmission. This means that each character is transmitted independently, allowing for irregular intervals between transmissions

                                  // Data is sent one character at a time, as opposed to blocks or frames used in synchronous transmission. This means that each character is transmitted
                                  // Data is sent one character at a time, as opposed to blocks or frames used in synchronous transmission. This means that each character is transmitted
                                  // independently, allowing for
                                  // irregular intervals between transmissions.
                                  // Unlike synchronous transmission, where data is sent in fixed intervals dictated by a clock signal, asynchronous transmission allows for variable timing between characters. The receiver does not know when the next character will arrive until it detects the start bit. And a stream is like a hose that delivers water continuously.
                                  // You can fill up a bucket (process the data) as the water flows out. The data sent by the stream is essentially asynchronous data.
                                  // Let's understand futures in dart:
                                  // Future in Dart represents a value that may not be immediately available but will be at some point in the future and hence used to handle asynchronous data in Flutter.
                                  // A
                                  // Future
                                  // object can be in one of two states:
                                  // Uncompleted
                                  // : The operation is still ongoing.
                                  // Completed
                                  // : The operation has finished, either successfully with a value or with an error.

                                  //         '''))),
                                  onPressed: () => pickPDF(context),
                                  iconData: Icons.arrow_forward),
                              FrontWidget(
                                  text: "Watch Now",
                                  onPressed: () => _launchUrl(
                                      "https://youtu.be/ydlOXu-8uQg"),
                                  iconData: Icons.play_arrow)
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> pickPDF(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        isLoading = true;
        loadingText = "Trying to extract data from the PDF";
      });

      // Use Uint8List instead of File
      Uint8List fileBytes = result.files.single.bytes!;
      setState(() {
        pickedBytes = fileBytes;
      });
      // Load the PDF document from bytes
      final PdfDocument document = PdfDocument(inputBytes: fileBytes);

      final PdfTextExtractor extractor = PdfTextExtractor(document);
      String text = extractor.extractText();

      extractedText = text;

      print(text); // Check if text extraction works

      List<TextLine> lines = extractor.extractTextLines();
      List<Map> model = [];
      for (int i = 0; i < lines.length; i++) {
        Map<String, dynamic> modelMap = {
          'fontName': lines[i].fontName.toString(),
          'fontSize': lines[i].fontSize,
          'text': lines[i].text
        };
        model.add(modelMap);
      }

      List<double> embedLists = [-0.02, -0.54];

      //authing
      User? user = await _auth.signInAnonymously();
      if (user != null) {
        // Perform actions after successful sign-in
        print("User ID: ${user.uid}");
        uploadAnonPDF(fileBytes, model, embedLists, user.uid);
        makeQuestionList(text, user.uid, context);
      } else {
        // Handle sign-in failure
        print("Sign-in failed.");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }

  Future<void> uploadAnonPDF(Uint8List fileBytes, List<Map> stringList,
      List embeddings, String uid) async {
    setState(() {
      loadingText = "Parsing and uploading pdf to database";
    });
    try {
      print("Starting upload...");
      String fileName =
          "uploaded_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf";

      Reference storageRef = FirebaseStorage.instance.ref('anonPDF/$fileName');
      // Upload the file bytes
      await storageRef.putData(fileBytes);
      print("Uploaded file to storage reference.");

      // Get the download URL
      String downloadURL = await storageRef.getDownloadURL();
      print("Uploaded to reference.");

      // Store metadata in Firestore
      await FirebaseFirestore.instance.collection('anonPDF').add({
        'name': fileName,
        'url': downloadURL,
        'uploaded_at': FieldValue.serverTimestamp(),
        'metadata': stringList,
        'uid': uid
      });

      print("Uploaded to Firestore instance.");
      print('PDF uploaded successfully! URL: $downloadURL');
    } catch (e) {
      print('Error uploading PDF: $e');
    }
  }

  Future embeddings(String embeddings) async {
    print("starting..");
    final model1 = GenerativeModel(
        model: 'text-embedding-004', apiKey: Constants.geminiApiKey);
    final content = Content.text(embeddings);

    // Generate embedding
    final result = await model1.embedContent(content);
    final embedding = result.embedding.values;

    print(embedding);
    return embedding;
  }

  Future<String> generateResponses(String data) async {
    try {
      setState(() {
        loadingText = "Generating related questions";
      });
      // Await the result of gemini.generateFromText
      final value = await gemini.generateFromText('''
      Develop an engine that generates 3-5 insightful questions related to the promoted content. These questions should cover key themes, concepts, and points in the document. Make sure about the quality, relevance, and diversity of generated questions, And only print questions in lines:
      $data
    ''');
      print(value.text); // Print the generated response
      return value.text; // Return the response text
    } catch (e) {
      print(e); // Print any errors
      return ''; // Return an empty string or handle error appropriately
    }
  }

  void makeQuestionList(String text, String uid, BuildContext context) async {
    try {
      String response = await generateResponses(text);
      if (response.isNotEmpty) {
        print("Responses are generated successfully.");

        List<String> questions = response
            .split('\n')
            .map((line) => line.replaceFirst(
                RegExp(r'^\s*-\s*'), '')) // Remove leading '-'
            .where((line) => line.trim().isNotEmpty) // Filter out empty lines
            .toList();

        setState(() {
          responseByGemini = response;
          questionsList = questions;
          isLoading = false;
        });

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => QueryScreen(
                    questions: questions,
                    extractedText: extractedText!,
                    uid: uid)));

        print("State set.");
      } else {
        print("No valid response received.");
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  getLogStatus(context) async {
    await _prefs.getLogStatus().then((a) {
      print("LogStatus: $a");
      setState(() {
        if (a != null) {
          isLoggedIn = a;
        }
      });

      if (isLoggedIn) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const Dashboard()));
      }
    });
  }

  getUserData() async {
    String? name;
    String? email;
    String? uid;

    await _prefs.getName().then((val) {
      name = val;
    });
    await _prefs.getEmail().then((val) {
      email = val;
    });
    await _prefs.getUID().then((val) {
      uid = val;
    });
    print(uid);
    Constants.localUsername = name ?? "null";
    Constants.localEmail = email!;
    Constants.localUID = uid!;
  }

  Future<void> _launchUrl(String _url) async {
    if (!await launchUrl(Uri.parse(_url))) {
      throw Exception('Could not launch $_url');
    }
  }
}
