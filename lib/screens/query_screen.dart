import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_gemini/google_gemini.dart';
import 'package:pdf_parser/constants/constants.dart';
import 'package:pdf_parser/constants/query.dart';

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
  List<bool>? showCitationsList; // List to track visibility of citations

  bool isLoading = false;

  void _generateResponse() async {
    setState(() {
      isLoading = true;
    });
    questions.add(queryController.text.trim());
    Query queryInstance = Query();
    String query = queryInstance.queryGenerator(
        widget.extractedText, queryController.text.trim());
    final value = await gemini.generateFromText(query);
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

    setState(() {
      isLoading = false;
      queryController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    showCitationsList = List<bool>.filled(100, false); // Initialize with false
  }

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
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
                  isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                          color: Colors.black87,
                        ))
                      : SingleChildScrollView(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height / 2,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: responses
                                  .length, // Number of items in the list
                              itemBuilder: (BuildContext context, int index) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(
                                        questions[index],
                                        style: GoogleFonts.archivo(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SelectableText(responses[index],
                                          style: GoogleFonts.archivo(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w400)),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            showCitationsList![index] =
                                                !(showCitationsList![index]);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.lightGreenAccent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                              "Show Citations"), // Add text for clarity
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      // Only show citations if showCitations is true
                                      if (showCitationsList![index] &&
                                          c.isNotEmpty) ...[
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: List.generate(
                                              (c[index]).length, (i) {
                                            return Align(
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Text(
                                                    "${(i + 1)}.",
                                                    style: GoogleFonts.archivo(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  const SizedBox(
                                                    width: 8,
                                                  ),
                                                  SizedBox(
                                                    width: 400,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        SelectableText(
                                                          c[index][i][
                                                                  'previous_line'] ??
                                                              "",
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 8),
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              color: Colors
                                                                  .yellow),
                                                          child: SelectableText(c[
                                                                      index][i][
                                                                  'actual_citation'] ??
                                                              ""),
                                                        ),
                                                        SelectableText(c[index]
                                                                    [i]
                                                                ['next_line'] ??
                                                            ""),
                                                        const SizedBox(
                                                            height:
                                                                10), // Add spacing between citations
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                      const SizedBox(
                                          height:
                                              30), // Space after each response
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                  const Spacer(),
                  SingleChildScrollView(
                    child: Column(
                      // mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SelectableText(
                            'Related Questions',
                            style: GoogleFonts.archivo(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                        SizedBox(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: widget.questions.length,
                            itemBuilder: (context, index) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        queryController.text =
                                            widget.questions[index].toString();
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Text(
                                        widget.questions[index].toString(),
                                        style: GoogleFonts.archivo(
                                            fontWeight: FontWeight.w400),
                                      ),
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
                                    onFieldSubmitted: (value) {
                                      if (!isLoading) {
                                        _generateResponse();
                                      } // Call submit when Enter is pressed
                                    },
                                    controller: queryController,
                                    decoration: InputDecoration(
                                      hintText: "Type your query here...",
                                      hintStyle: GoogleFonts.archivo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w300),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                        if (!isLoading) {
                                          _generateResponse();
                                        }
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
                    ),
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
