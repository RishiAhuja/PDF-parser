import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_gemini/google_gemini.dart';
import 'package:pdf_parser/constants/constants.dart';

class QueryScreen extends StatefulWidget {
  const QueryScreen(
      {super.key, required this.questions, required this.extractedText});

  final List questions;
  final String extractedText;

  @override
  State<QueryScreen> createState() => _QueryScreenState();
}

class _QueryScreenState extends State<QueryScreen> {
  TextEditingController queryController = TextEditingController();
  String markdownData = """
  ## Ask a query
  """;
  final gemini = GoogleGemini(
    apiKey: Constants.geminiApiKey,
  );

  List<String> questions = [];
  List<String> responses = [];
  List c = [];
  bool showCitations = true;

  void _generateResponse() async {
    // questions.add(queryController.text.trim());
    // final value = await gemini.generateFromText('''
    //   I will provide you with some text and a question, generate responses based on that question and the text:
    //   question: ${queryController.text.trim()},

    //   text: ${widget.extractedText}

    // ''');
    // queryController.clear();
    // setState(() {
    //   markdownData = value.text;
    //   responses.add(value.text);
    // });
    questions.add(queryController.text.trim());
    final value = await gemini.generateFromText('''
I will give you some data, which will include a text, and a question related to a text:

I would want you to please, make a JSON response, and dont respond with markdown, just pure string, but a string of a large JSON response, which will have a structutre like this:

{
    questionResult: ""
    citations: [
            {  
                "actual_citation": "Actual Line of Citation",
                "previous_line": "A line before the actual citation",
                "next_line": "A next to the actual citation",
            }
            {  
                "actual_citation": "Actual Line of Citation",
                "previous_line": "A line before the actual citation",
                "next_line": "A next to the actual citation",
            }
            {  
                "actual_citation": "Actual Line of Citation",
                "previous_line": "A line before the actual citation",
                "next_line": "A next to the actual citation",
            }

        ]
}

text from which the citations will be generated: ${widget.extractedText}

the question for which the questionResult will be generated based on the given text: ${queryController.text.trim()}

the answer of the question which will go inside "questionResult" should be generated by you, you just need to use the given text as an argument, and just generate the json.
      
    ''');
    // print(value.text); // Print the generated response

    Map<String, dynamic> parsedJson = jsonDecode(value.text);

    print("Question Result: ${parsedJson['questionResult']}");

    // Accessing citations
    List<dynamic> citationsList = parsedJson['citations'];

    // Convert citations to a list of maps (or custom objects if needed)
    List<Map<String, dynamic>> citations =
        List<Map<String, dynamic>>.from(citationsList);

    setState(() {
      responses.add(parsedJson['questionResult'].toString());
      c.add(citations);
    });

    for (var citation in citations) {
      print("Citation: ${citation['actual_citation']}");
      print("Previous Line: ${citation['previous_line']}");
      print("Next Line: ${citation['next_line']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: const BoxDecoration(color: Colors.black87),
              child: SingleChildScrollView(
                // Wrap Column with SingleChildScrollView
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align text to start
                    children: [
                      Text(
                        "Extracted Text",
                        style: GoogleFonts.archivo(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10), // Optional spacing
                      Text(
                        widget.extractedText.isNotEmpty
                            ? widget.extractedText
                            : "No content extracted.",
                        style: GoogleFonts.archivo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const SizedBox(height: 40),
                  // SizedBox(
                  //   height: MediaQuery.of(context).size.height / 2,
                  //   child: ListView.builder(
                  //     shrinkWrap: true,
                  //     itemCount:
                  //         responses.length, // Number of items in the list
                  //     itemBuilder: (BuildContext context, int index) {
                  //       return Container(
                  //         padding: const EdgeInsets.symmetric(horizontal: 20),
                  //         child: Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             Text(
                  //               questions[index],
                  //               style: GoogleFonts.archivo(
                  //                   color: Colors.black87,
                  //                   fontWeight: FontWeight.bold),
                  //             ),
                  //             Text(responses[index],
                  //                 style: GoogleFonts.archivo(
                  //                     color: Colors.black87,
                  //                     fontWeight: FontWeight.w400)),
                  //             const SizedBox(height: 8),
                  //             GestureDetector(
                  //               onTap: () {
                  //                 setState(() {
                  //                   showCitations = true;
                  //                 });
                  //               },
                  //               child: Container(
                  //                 padding: const EdgeInsets.symmetric(
                  //                     horizontal: 8, vertical: 5),
                  //                 decoration: BoxDecoration(
                  //                   color: Colors.lightGreenAccent,
                  //                   borderRadius: BorderRadius.circular(8),
                  //                 ),
                  //               ),
                  //             ),
                  //             ListView.builder(
                  //               itemCount:
                  //                   c.length, // Number of items in the list
                  //               itemBuilder: (BuildContext context, int index) {
                  //                 return Column(
                  //                   children: [
                  //                     Text(c[index]['previous_line'] ?? "null"),
                  //                     Container(
                  //                         decoration: const BoxDecoration(
                  //                             color: Colors.yellow),
                  //                         child: Text(
                  //                             c[index]['actual_citation'])),
                  //                     Text(c[index]['next_line'] ?? "null"),
                  //                   ],
                  //                 );
                  //               },
                  //             ),
                  //             const SizedBox(
                  //               height: 30,
                  //             ),
                  //           ],
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),

                  SizedBox(
                    height: MediaQuery.of(context).size.height / 2,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          responses.length, // Number of items in the list
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                questions[index],
                                style: GoogleFonts.archivo(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(responses[index],
                                  style: GoogleFonts.archivo(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w400)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.lightGreenAccent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                      "Citations"), // Add text for clarity
                                ),
                              ),
                              // Only show citations if showCitations is true
                              if (showCitations && c.isNotEmpty) ...[
                                Column(
                                  children: List.generate(c.length, (i) {
                                    return Column(
                                      children: [
                                        Text(c[index][i]['previous_line'] ??
                                            "null"),
                                        Container(
                                          decoration: const BoxDecoration(
                                              color: Colors.yellow),
                                          child: Text(
                                              c[index][i]['actual_citation']),
                                        ),
                                        Text(
                                            c[index][i]['next_line'] ?? "null"),
                                        const SizedBox(
                                            height:
                                                10), // Add spacing between citations
                                      ],
                                    );
                                  }),
                                ),
                              ],
                              const SizedBox(
                                  height: 30), // Space after each response
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(),
                  Column(
                    // mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.questions.length,
                          itemBuilder: (context, index) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    widget.questions[index].toString(),
                                    style: GoogleFonts.archivo(
                                        fontWeight: FontWeight.w400),
                                  ),
                                ),
                                if (index != widget.questions.length - 1)
                                  const Divider()
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Form(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 10,
                                child: TextFormField(
                                  controller: queryController,
                                  decoration: InputDecoration(
                                    hintText: "Type your query here...",
                                    hintStyle: GoogleFonts.archivo(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w300),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 20),
                                  ),
                                  style: GoogleFonts.archivo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w300),
                                ),
                              ),
                              Expanded(
                                  flex: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      _generateResponse();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ))
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
