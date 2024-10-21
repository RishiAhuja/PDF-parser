import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_gemini/google_gemini.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pdf_parser/constants/constants.dart';
import 'package:pdf_parser/screens/query_screen.dart';
import 'package:pdf_parser/widgets/front_button.dart';
import 'package:sizer/sizer.dart';

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
            home: const MyHomePage());
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final gemini = GoogleGemini(
    apiKey: Constants.geminiApiKey,
  );

  String? responseByGemini;
  List questionsList = [];
  bool isLoading = false;
  String loadingText = "Trying to extract data from the PDF";
  String? extractedText;
  Uint8List? pickedBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: isLoading
          ? Center(
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
            )
          : Container(
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
                        FrontWidget(
                            text: "Upload Document",
                            onPressed: () => pickPDF(context),
                            iconData: Icons.arrow_forward),
                        FrontWidget(
                            text: "Watch Now",
                            onPressed: () => Future.delayed(Duration.zero),
                            iconData: Icons.play_arrow)
                      ],
                    )
                  ],
                ),
              ),
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

      uploadPDF(fileBytes, model, embedLists);

      // Continue with your logic...
      makeQuestionList(text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }

  Future<void> uploadPDF(
      Uint8List fileBytes, List<Map> stringList, List embeddings) async {
    setState(() {
      loadingText = "Parsing and uploading pdf to database";
    });
    try {
      print("Starting upload...");

      // Use a unique file name or derive it from your context
      String fileName =
          "uploaded_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf";

      Reference storageRef = FirebaseStorage.instance.ref('pdfs/$fileName');

      // Upload the file bytes
      await storageRef.putData(fileBytes);
      print("Uploaded file to storage reference.");

      // Get the download URL
      String downloadURL = await storageRef.getDownloadURL();
      print("Uploaded to reference.");

      // Store metadata in Firestore
      await FirebaseFirestore.instance.collection('pdfs').add({
        'name': fileName,
        'url': downloadURL,
        'uploaded_at': FieldValue.serverTimestamp(),
        'metadata': stringList,
        'embeddings': embeddings,
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

  void makeQuestionList(String text) async {
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
                    questions: questions, extractedText: extractedText!)));

        print("State set.");
      } else {
        print("No valid response received.");
      }
    } catch (error) {
      print('Error: $error');
    }
  }
}
