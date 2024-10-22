import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_gemini/google_gemini.dart';
import 'package:intl/intl.dart';
import 'package:pdf_parser/constants/constants.dart';
import 'package:pdf_parser/main.dart';
import 'package:pdf_parser/screens/query_screen.dart';
import 'package:pdf_parser/services/auth.dart';
import 'package:pdf_parser/services/database.dart';
import 'package:pdf_parser/services/shared_prefs.dart';
import 'package:pdf_parser/widgets/front_button.dart';
import 'package:pdf_parser/widgets/navbar_button.dart';
import 'package:sizer/sizer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final SharedPrefMethods _prefs = SharedPrefMethods();
  final DatabaseMethods _database = DatabaseMethods();
  final AuthMethods _auth = AuthMethods();
  bool isUploading = false;
  bool isGeneretingResponses = false;
  final gemini = GoogleGemini(
    apiKey: Constants.geminiApiKey,
  );
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(225, 22, 22, 22),
      body: isGeneretingResponses
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF2542A3)),
                  const SizedBox(
                    height: 15,
                  ),
                  Text("Generating related questions..",
                      style: GoogleFonts.archivo(color: Colors.white))
                ],
              ),
            )
          : Center(
              child: Column(
                children: [
                  //---------NavbarStart-------
                  Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        // height: 80,
                        color: const Color.fromARGB(225, 22, 22, 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const NavbarButton(
                              text: "PDF Parser",
                              color: Colors.black,
                            ),
                            GestureDetector(
                              onTap: () async {
                                await _prefs.setLogStatus(false);
                                _auth.signOut();

                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AnonPage()));
                              },
                              child: const NavbarButton(
                                text: "Logout",
                                color: Color(0xFF2542A3),
                              ),
                            )
                          ],
                        ),
                      )),
                  //---------NavbarEnd-------

                  Device.orientation == Orientation.landscape
                      ? Expanded(
                          flex: 10,
                          child: Container(
                              color: const Color.fromARGB(225, 22, 22, 22),
                              child: Row(
                                children: [
                                  Expanded(flex: 1, child: uploadButton()),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height / 2,
                                    child: const VerticalDivider(
                                      color: Color.fromARGB(255, 71, 71, 71),
                                    ),
                                  ),
                                  Expanded(flex: 2, child: uploadedPdfStream())
                                ],
                              )),
                        )
                      : Expanded(
                          flex: 10,
                          child: Container(
                              color: const Color.fromARGB(225, 22, 22, 22),
                              child: Column(
                                children: [
                                  Expanded(flex: 1, child: uploadButton()),
                                  Expanded(flex: 10, child: uploadedPdfStream())
                                ],
                              )),
                        )
                ],
              ),
            ),
    );
  }

  Future<void> pickAndSendData(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      Uint8List fileBytes = result.files.single.bytes!;
      final PdfDocument document = PdfDocument(inputBytes: fileBytes);

      final PdfTextExtractor extractor = PdfTextExtractor(document);
      String text = extractor.extractText();
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
      setState(() {
        isUploading = true;
      });
      uploadData(fileBytes, model, text);
    }
  }

  Future<void> uploadData(
      Uint8List fileBytes, List<Map> stringList, text) async {
    try {
      print("Starting upload...");
      String fileName =
          "uploaded_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf";

      Reference storageRef = FirebaseStorage.instance.ref('PDF/$fileName');
      // Upload the file bytes
      await storageRef.putData(fileBytes);
      print("Uploaded file to storage reference.");

      String downloadURL = await storageRef.getDownloadURL();
      print("Uploaded to reference.");

      String? uid;
      await _prefs.getUID().then((val) {
        uid = val!;
        print(val);
      });
      // Store metadata in Firestore
      _database.addPdfData({
        'name': fileName,
        'url': downloadURL,
        'uploaded_at': DateTime.now().millisecondsSinceEpoch,
        'metadata': stringList,
        'uid': uid!,
        'text': text
      }, uid!);

      print("Uploaded to Firestore instance & collection.");
      print('PDF uploaded successfully! URL: $downloadURL');

      setState(() {
        isUploading = false;
      });
    } catch (e) {
      print('Error uploading PDF: $e');
    }
  }
  //get user data

  Widget uploadButton() {
    return Center(
      child: isUploading
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  "The file is being uploaded to the server",
                  style: GoogleFonts.dmMono(color: Colors.white, fontSize: 16),
                ),
              ],
            )
          : GestureDetector(
              onTap: () => setState(() {
                isUploading = true;
              }),
              child: SizedBox(
                height: 70,
                child: FrontWidget(
                    text: "Upload New PDF",
                    onPressed: () => pickAndSendData(context),
                    iconData: Icons.upload),
              ),
            ),
    );
  }

  Widget uploadedPdfStream() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Uploaded Documents",
                style: GoogleFonts.dmMono(color: Colors.white, fontSize: 22)),
            const SizedBox(height: 18),
            SizedBox(
              height: MediaQuery.of(context).size.height / 2,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(Constants.localUID)
                    .collection("pdf")
                    .orderBy("uploaded_at", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  // Check for errors
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  // Check if the snapshot has data
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Retrieve the list of documents
                  final List<DocumentSnapshot> documents = snapshot.data!.docs;

                  // Check if there are no documents
                  if (documents.isEmpty) {
                    return Center(
                        child: Text(
                      'No PDFs uploaded, Click on upload button to get started.',
                      style: GoogleFonts.dmMono(color: Colors.white),
                    ));
                  }

                  // Build a list view of the documents
                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      var data =
                          documents[index].data() as Map<String, dynamic>;
                      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
                          data['uploaded_at']);
                      String formattedDate =
                          DateFormat('HH:mm dd-MM-yyyy').format(dateTime);
                      return GestureDetector(
                        onTap: () =>
                            makeQuestionList(data["text"], data["uid"]),
                        child: Card(
                          color: const Color(0xFF2542A3),
                          child: ListTile(
                            title: SizedBox(
                              // height: 40,
                              child: Text(
                                '${data['text']}....',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: GoogleFonts.archivo(color: Colors.white),
                              ),
                            ),
                            subtitle: Text(
                              formattedDate,
                              style: GoogleFonts.archivo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void makeQuestionList(String text, String uid) async {
    try {
      setState(() {
        isGeneretingResponses = true;
      });
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
          isGeneretingResponses = false;
        });
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => QueryScreen(
                    questions: questions, extractedText: text, uid: uid)));

        print("State set.");
      } else {
        print("No valid response received.");
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<String> generateResponses(String data) async {
    try {
      final value = await gemini.generateFromText('''
      Develop an engine that generates 3-5 insightful questions related to the promoted content. These questions should cover key themes, concepts, and points in the document. Make sure about the quality, relevance, and diversity of generated questions, And only print questions in lines:
      $data
    ''');
      print(value.text);
      return value.text;
    } catch (e) {
      print(e);
      return '';
    }
  }
}
