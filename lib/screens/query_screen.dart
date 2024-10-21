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
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/background.webp"),
                      fit: BoxFit
                          .cover, // Ensures the image covers the entire container
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: SingleChildScrollView(
                    // Wrap Column with SingleChildScrollView
                    child: SizedBox(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // Align text to start
                        children: [
                          Text(
                            "Extracted Text",
                            style: GoogleFonts.dmMono(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20), // Optional spacing
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Text(
                              widget.extractedText.isNotEmpty
                                  ? widget.extractedText
                                  : "No content extracted.",
                              textAlign: TextAlign.justify,
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 7,
            child: Container(
              decoration: const BoxDecoration(color: Colors.black87),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const SizedBox(height: 40),
                  isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 234, 234, 234),
                        ))
                      : SingleChildScrollView(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height / 2.1,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: responses
                                  .length, // Number of items in the list
                              itemBuilder: (BuildContext context, int index) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2.5,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SelectableText(
                                          questions[index],
                                          style: GoogleFonts.dmMono(
                                              color: Colors.white,
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        SelectableText(responses[index],
                                            style: GoogleFonts.archivo(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400)),
                                        const SizedBox(height: 10),
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
                                              color: Colors.black87,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              image: const DecorationImage(
                                                image: AssetImage(
                                                    "assets/images/background2.webp"),
                                                fit: BoxFit
                                                    .cover, // Ensures the image covers the entire container
                                              ),
                                            ),
                                            child: Text(
                                              "Show Citations",
                                              style: GoogleFonts.dmMono(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w300),
                                            ), // Add text for clarity
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
                                                      style:
                                                          GoogleFonts.archivo(
                                                              fontSize: 20,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
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
                                                            style: GoogleFonts
                                                                .archivo(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
                                                                    color: Colors
                                                                        .white),
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical:
                                                                        4),
                                                            decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6),
                                                                color: const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    189,
                                                                    171,
                                                                    7)),
                                                            child:
                                                                SelectableText(
                                                              c[index][i][
                                                                      'actual_citation'] ??
                                                                  "",
                                                              style: GoogleFonts.archivo(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w300,
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ),
                                                          SelectableText(
                                                            c[index][i][
                                                                    'next_line'] ??
                                                                "",
                                                            style: GoogleFonts
                                                                .archivo(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
                                                                    color: Colors
                                                                        .white),
                                                          ),
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
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 10),
                    // decoration:
                    //     BoxDecoration(border: Border.all(color: Colors.grey)),
                    child: Column(
                      // mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          // width: MediaQuery.of(context).size.width / 2.3,
                          // decoration: BoxDecoration(
                          //     border: Border.all(color: Colors.grey)),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.library_books_sharp,
                                      color: Colors.white,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: SelectableText(
                                        'Related Questions',
                                        style: GoogleFonts.dmMono(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 20),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: widget.questions.length,
                                    itemBuilder: (context, index) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  widget.questions[index]
                                                      .toString(),
                                                  maxLines:
                                                      1, // Limit the number of lines
                                                  overflow: TextOverflow
                                                      .ellipsis, // This won't work directly
                                                  style: GoogleFonts.archivo(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w400),
                                                ),
                                                const Spacer(),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      queryController.text =
                                                          widget
                                                              .questions[index]
                                                              .toString();
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(100),
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 79, 79, 79)),
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    child: const Icon(
                                                      Icons.add,
                                                      size: 16,
                                                      color: Color.fromARGB(
                                                          255, 234, 234, 234),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 15,
                                                )
                                              ],
                                            ),
                                          ),
                                          if (index !=
                                              widget.questions.length - 1)
                                            const Divider(
                                              color: Color.fromARGB(
                                                  255, 79, 79, 79),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Form(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: const Color.fromARGB(221, 47, 47, 47),
                                  borderRadius: BorderRadius.circular(30)),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    // flex: 10,
                                    child: TextFormField(
                                      onFieldSubmitted: (value) {
                                        if (!isLoading) {
                                          _generateResponse();
                                        } // Call submit when Enter is pressed
                                      },
                                      controller: queryController,
                                      decoration: InputDecoration(
                                        hintText: "Ask a question",
                                        hintStyle: GoogleFonts.archivo(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w300,
                                            fontSize: 18),
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
                                  GestureDetector(
                                    onTap: () {
                                      if (!isLoading) {
                                        _generateResponse();
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          color: const Color.fromARGB(
                                              255, 79, 79, 79)),
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.arrow_upward_outlined,
                                        color:
                                            Color.fromARGB(255, 234, 234, 234),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 15,
                                  )
                                ],
                              ),
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
