import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_gemini/google_gemini.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pdf_parser/constants/constants.dart';
import 'package:pdf_parser/screens/query_screen.dart';

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
    return MaterialApp(
        title: 'PDF parser',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        // home: const QueryScreen(
        //   questions: [
        //     "What advantages and disadvantages come with using asynchronous data transmission compared to synchronous transmission?",
        //     "How do streams differ from other forms of data transfer, and what are their key benefits?",
        //     "Explain the concept of futures in Dart and how they are used to handle asynchronous operations.",
        //     "What are the potential use cases for asynchronous data, streams, and futures in real-world applications?",
        //     "How does the use of start and stop bits in asynchronous transmission impact the efficiency and reliability of data?"
        //   ],
        // ));

        home: MyHomePage());
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
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Simplify Document Research",
                    style: GoogleFonts.archivo(
                        color: Colors.black87,
                        fontSize: 60,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Upload, Analyze, and Extract Knowledge instantly!",
                    style: GoogleFonts.roboto(
                        color: Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () => pickPDF(context),
                    child: Row(
                      mainAxisSize: MainAxisSize
                          .min, // This ensures the Row takes minimum width
                      children: [
                        Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.black87,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Upload your document now",
                                style: GoogleFonts.archivo(color: Colors.white),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Container(
                                  padding: const EdgeInsets.all(5),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                        color: Constants.backgroundColor),
                                    color: Colors.black87,
                                  ),
                                  child: Icon(Icons.arrow_forward_rounded,
                                      size: 18,
                                      color: Constants.backgroundColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  // Future<void> pickPDF(BuildContext context) async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ['pdf'],
  //   );

  //   if (result != null) {
  //     setState(() {
  //       isLoading = true;
  //     });
  //     File file = File(result.files.single.path!);

  //     String path = result.files.single.path!;

  //     // Load the PDF document
  //     final PdfDocument document =
  //         PdfDocument(inputBytes: File(path).readAsBytesSync());

  //     final PdfTextExtractor extractor = PdfTextExtractor(document);
  //     // Extract text from all pages
  //     String text = extractor.extractText();

  //     print(text);

  //     // Optionally, extract text with formatting information
  //     List<TextLine> lines = extractor.extractTextLines();

  //     List<Map> model = [];
  //     for (int i = 0; i < lines.length; i++) {
  //       Map<String, dynamic> modelMap = {
  //         'fontName': lines[i].fontName.toString(),
  //         'fontSize': lines[i].fontSize,
  //         'text': lines[i].text
  //       };
  //       model.add(modelMap);
  //     }

  //     // List<double> embedLists = await embeddings(text);

  //     List<double> embedLists = [
  //       0.05537452,
  //       0.05257315,
  //       -0.036295507,
  //       0.008237362,
  //       0.021834228,
  //       0.054557648,
  //       0.03687299,
  //       0.033815816,
  //       0.0058602816,
  //       -0.032275323,
  //       -0.035795037,
  //       0.0025158352,
  //       -0.004263709,
  //       -0.0074944934,
  //       -0.023983082,
  //       -0.013726047,
  //       0.07460791,
  //       0.039006736,
  //       -0.016828535,
  //       -0.033668183,
  //       -0.042583663,
  //       -0.01932476,
  //       -0.04770951,
  //       -0.038692005,
  //       0.01349986,
  //       -0.05063446,
  //       0.05201206,
  //       -0.010596106,
  //       -0.0028296944,
  //       0.0012711956,
  //       0.029907066,
  //       0.049524117,
  //       0.02200814,
  //       -0.055127777,
  //       -0.026242146,
  //       0.04583213,
  //       0.020855967,
  //       0.005611414,
  //       0.060112197,
  //       -0.038615353,
  //       -0.076776244,
  //       -0.009415655,
  //       -0.00997938,
  //       0.06381351,
  //       -0.023580287,
  //       -0.033419326,
  //       -0.03995351,
  //       0.042031087,
  //       0.021732021,
  //       0.01603197,
  //       0.026294744,
  //       -0.047449958,
  //       -0.06864778,
  //       0.010986972,
  //       -0.030732943,
  //       -0.026631078,
  //       -0.012895069,
  //       0.0051858155,
  //       0.041450184,
  //     ];
  //     setState(() {
  //       loadingText = "Uploading the embeddings and PDF to the server";
  //     });
  //     // await uploadPDF(file, model, embedLists);
  //     // ScaffoldMessenger.of(context).showSnackBar(
  //     //   SnackBar(content: Text('Uploaded ${result.files.single.name}')),
  //     // );
  //     makeQuestionList(text);
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('No file selected')),
  //     );
  //   }
  // }

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

      // List<double> embedLists = [-0.02, -0.54];

      // uploadPDF(fileBytes, model, embedLists);

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
      // String response = await generateResponses(text);
      String response = '''
      - What advantages and disadvantages come with using asynchronous data transmission compared to synchronous transmission?
      - How do streams differ from other forms of data transfer, and what are their key benefits?
      - Explain the concept of futures in Dart and how they are used to handle asynchronous operations.
      - What are the potential use cases for asynchronous data, streams, and futures in real-world applications?
      - How does the use of start and stop bits in asynchronous transmission impact the efficiency and reliability of data?
      ''';
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
