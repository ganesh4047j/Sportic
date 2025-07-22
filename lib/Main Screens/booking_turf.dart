import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'booking_slot.dart'; // adjust the path if needed

class Comment {
  String username;
  String text;
  int likes;
  int dislikes;
  bool isLiked;
  bool isDisliked;
  List<Comment> replies;
  bool showReplyField;

  Comment({
    required this.username,
    required this.text,
    this.likes = 0,
    this.dislikes = 0,
    this.isLiked = false,
    this.isDisliked = false,
    this.replies = const [],
    this.showReplyField = false,
  });
}

class BookingPage extends StatefulWidget {
  final String turfImages;
  final String turfName;
  final String location;

  const BookingPage({
    super.key,
    required this.turfImages,
    required this.turfName,
    required this.location,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}
class _BookingPageState extends State<BookingPage> {
  final PageController _pageController = PageController();



  // final List<String> turfImages = [
  //   'https://th.bing.com/th/id/OIP.IIfvWqSDnPM1m8m1d7A8yAHaFC?w=268&h=183&c=7&r=0&o=5&dpr=1.3&pid=1.7',
  //   'https://th.bing.com/th/id/OIP.IIfvWqSDnPM1m8m1d7A8yAHaFC?w=268&h=183&c=7&r=0&o=5&dpr=1.3&pid=1.7',
  //   'https://th.bing.com/th/id/OIP.IIfvWqSDnPM1m8m1d7A8yAHaFC?w=268&h=183&c=7&r=0&o=5&dpr=1.3&pid=1.7',
  // ];
  final List<String> sports = [
    'Cricket',
    'Football',
    'Badminton',
    'Tennis',
    'Basketball',
  ];
  int selectedCardIndex = -1;
  List<Comment> comments = [
    Comment(
      username: "@godwinjeraldwilliam",
      text: "Smooth and Even Surface",
      likes: 125,
    ),
    Comment(username: "@anotheruser", text: "Great turf quality", likes: 45),
  ];

  Widget _buildCommentTile(Comment comment, {int indentLevel = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * indentLevel, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mail_outline, size: 30, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.text,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (comment.isLiked) {
                                comment.isLiked = false;
                                comment.likes--;
                              } else {
                                comment.isLiked = true;
                                comment.likes++;
                                if (comment.isDisliked) {
                                  comment.isDisliked = false;
                                  comment.dislikes--;
                                }
                              }
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.thumb_up,
                                color:
                                    comment.isLiked
                                        ? Colors.white
                                        : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likes}',
                                style: TextStyle(
                                  color:
                                      comment.isLiked
                                          ? Colors.white
                                          : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (comment.isDisliked) {
                                comment.isDisliked = false;
                                comment.dislikes--;
                              } else {
                                comment.isDisliked = true;
                                comment.dislikes++;
                                if (comment.isLiked) {
                                  comment.isLiked = false;
                                  comment.likes--;
                                }
                              }
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.thumb_down,
                                color:
                                    comment.isDisliked
                                        ? Colors.white
                                        : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${comment.dislikes}',
                                style: TextStyle(
                                  color:
                                      comment.isDisliked
                                          ? Colors.white
                                          : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              comment.showReplyField = !comment.showReplyField;
                            });
                          },
                          child: Text(
                            'reply',
                            style: GoogleFonts.cutive(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    if (comment.showReplyField)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                style: GoogleFonts.cutive(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Write a reply...',
                                  hintStyle: GoogleFonts.cutive(
                                    color: Colors.white70,
                                  ),
                                  border: UnderlineInputBorder(),
                                ),
                                onSubmitted: (replyText) {
                                  if (replyText.trim().isNotEmpty) {
                                    setState(() {
                                      comment.replies.add(
                                        Comment(
                                          username: "@you",
                                          text: replyText,
                                        ),
                                      );
                                      comment.showReplyField = false;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Render Replies Recursively
          for (var reply in comment.replies)
            _buildCommentTile(reply, indentLevel: indentLevel + 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> limitedImages = [widget.turfImages];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF452152),
              Color(0xFF3D1A4A),
              Color(0xFF200D28),
              Color(0xFF1B0723),
            ],
          ),
        ),
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: widget.turfImages.length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(25),
                                  bottomRight: Radius.circular(25),
                                ),
                                child: Image.network(
                                  widget.turfImages[index],
                                  fit: BoxFit.cover,
                                ),
                              );
                            },

                          ),
                        ),
                        Positioned(
                          top: 30,
                          left: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SmoothPageIndicator(
                              controller: _pageController,
                              // count: widget.turfImage.length,
                              count: limitedImages.length,
                              effect: const WormEffect(
                                dotColor: Colors.white54,
                                activeDotColor: Colors.white,
                                dotHeight: 8,
                                dotWidth: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.turfName,
                            style: GoogleFonts.robotoSlab(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.location,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "4.0 [4]",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "About Turf",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  print("Contact card tapped!");
                                },
                                child: Container(
                                  width: 150,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xf4fb965b),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Contact",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.phone_callback,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    print("Calling...");
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(6, (index) {
                                return Container(
                                  width: 170,
                                  height: 70,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.percent_outlined,
                                        size: 30,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Flat Rs.200 off",
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            "On all slots",
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "Available Sports",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(5, (index) {
                                bool isSelected = selectedCardIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedCardIndex = index;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Colors.green
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      sports[index],
                                      style: GoogleFonts.cutive(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "Venue info",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5), // spacing before the card
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                      ), // adjust the value as needed
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              print("Green card tapped");
                            },
                            child: Container(
                              width: 60,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "pitch",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              ".1 Nets",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 16.0,
                      ), // Add left padding here
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8, width: 20),
                          Text(
                            "Artificial Turf",
                            style: GoogleFonts.robotoSlab(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Equipment Provided",
                            style: GoogleFonts.robotoSlab(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8), // space before line
                          Divider(
                            color: Colors.white, // line color
                            thickness: 1,
                            indent: 10, // line thickness
                            endIndent: 35, // optional: line length control
                          ),
                          SizedBox(
                            height: 8,
                          ), // space after line before new text
                          Text(
                            "Amenities provided",
                            style: GoogleFonts.robotoSlab(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12), // space before amenity list
                          // ✅ List of amenities with green icons
                          Row(
                            children: [
                              Icon(
                                Icons.payments,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "UPI Accepted",
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.atm, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Card Accepted",
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.local_parking,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Free Parking",
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.family_restroom,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Toilets",
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Comments",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Optional: Input field to add comments
                          TextField(
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Write a comment...",
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.white70,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    comments.add(
                                      Comment(
                                        username: "@currentUser",
                                        text: "New comment here",
                                      ),
                                    );
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Comment list
                          ListView.builder(
                            itemCount: comments.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return _buildCommentTile(comment);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed bottom button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00c180), // vivid green
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ), // pill-shaped
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TimingPage()),
                  );
                },
                child: Text(
                  "PROCEED TO BOOK A SLOT",
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
