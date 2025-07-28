import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import 'dart:math';
import 'package:intl/intl.dart';

class BookingPage extends StatefulWidget {
  final String turfName;
  final String location;
  final String owner_id;
  final String creatorName;
  final int totalPlayers;
  final int needPlayers;

  const BookingPage({
    super.key,
    required this.owner_id,
    required this.turfName,
    required this.location,
    required this.creatorName,
    required this.totalPlayers,
    required this.needPlayers,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage>
    with TickerProviderStateMixin {
  String? selectedSport;
  DateTime _selectedDate = DateTime.now();
  int selectedStartHour =
      TimeOfDay.now().hour % 12 == 0 ? 12 : TimeOfDay.now().hour % 12;
  bool isStartAM = TimeOfDay.now().hour < 12;
  int selectedEndHour =
      ((TimeOfDay.now().hour + 1) % 12 == 0)
          ? 12
          : (TimeOfDay.now().hour + 1) % 12;
  bool isEndAM = (TimeOfDay.now().hour + 1) < 12;

  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _scaleAnimationController;
  late AnimationController _floatingAnimationController;
  late AnimationController _sparkleAnimationController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _sparkleAnimation;

  // Razorpay and Firestore related variables
  late Razorpay _razorpay;
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  bool isLoading = false;
  Map<String, dynamic>? adminDetails;
  Map<String, dynamic>? userProfile;
  String? bookingId;
  String? teamId;
  double bookingAmount = 500.0;

  List<Map<String, dynamic>> sports = [
    {'name': 'Football', 'icon': '⚽', 'color': Color(0xFF00C851)},
    {'name': 'Cricket', 'icon': '🏏', 'color': Color(0xFF007E33)},
    {'name': 'Basketball', 'icon': '🏀', 'color': Color(0xFFFF8800)},
    {'name': 'Tennis', 'icon': '🎾', 'color': Color(0xFF0099CC)},
    {'name': 'Hockey', 'icon': '🏑', 'color': Color(0xFF9933CC)},
    {'name': 'Pickleball', 'icon': '🏓', 'color': Color(0xFFCC0000)},
  ];

  List<int> hours = List.generate(12, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _initializeUserData();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _sparkleAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.linear,
      ),
    );

    _cardSlideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _floatingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _sparkleAnimationController,
        curve: Curves.linear,
      ),
    );

    _backgroundAnimationController.repeat();
    _cardAnimationController.forward();
    _fadeAnimationController.forward();
    _scaleAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);
    _floatingAnimationController.repeat(reverse: true);
    _sparkleAnimationController.repeat();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _cardAnimationController.dispose();
    _pulseAnimationController.dispose();
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
    _floatingAnimationController.dispose();
    _sparkleAnimationController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _initializeUserData() async {
    try {
      userProfile = await getUserProfile();
    } catch (e) {
      print('Error getting user profile: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      final emailDoc =
          await FirebaseFirestore.instance
              .collection('user_details_email')
              .doc(firebaseUser.uid)
              .get();

      if (emailDoc.exists) {
        final profile = emailDoc.data()!;
        return {
          'uid': firebaseUser.uid,
          'loginType': 'email',
          'name': profile['name'],
          'gender': profile['gender'],
          'email': profile['email'],
          'phone_number': profile['phone_number'],
          'location': profile['location'],
        };
      }
    }

    final customUid = await secureStorage.read(key: 'custom_uid');

    if (customUid != null) {
      final phoneDoc =
          await FirebaseFirestore.instance
              .collection('user_details_phone')
              .doc(customUid)
              .get();

      if (phoneDoc.exists) {
        final profile = phoneDoc.data()!;
        return {
          'uid': customUid,
          'loginType': 'phone',
          'name': profile['name'],
          'gender': profile['gender'],
          'email': profile['email'],
          'phone_number': profile['phone_number'],
          'location': profile['location'],
        };
      }
    }

    throw Exception("User not authenticated or profile not found.");
  }

  Future<Map<String, dynamic>?> getAdminDetails(String ownerId) async {
    try {
      final phoneDoc =
          await FirebaseFirestore.instance
              .collection('admin_details_phone')
              .doc(ownerId)
              .get();

      if (phoneDoc.exists) {
        return phoneDoc.data();
      }

      final emailDoc =
          await FirebaseFirestore.instance
              .collection('admin_details_email')
              .doc(ownerId)
              .get();

      if (emailDoc.exists) {
        return emailDoc.data();
      }

      return null;
    } catch (e) {
      print('Error getting admin details: $e');
      return null;
    }
  }

  String generateBookingId() {
    final now = DateTime.now();
    return 'BK${now.millisecondsSinceEpoch}${widget.owner_id.substring(0, 4)}';
  }

  String generateTeamId() {
    final now = DateTime.now();
    return 'TM${now.millisecondsSinceEpoch}${widget.owner_id.substring(0, 4)}';
  }

  String formatHour(int hour, bool isAM) {
    return '$hour ${isAM ? 'AM' : 'PM'}';
  }

  void _initiatePayment() async {
    // Validate user profile
    if (userProfile == null) {
      _showErrorDialog('Please log in to continue with booking.');
      return;
    }

    // Validate sport selection
    if (selectedSport == null) {
      _showErrorDialog('Please select a sport before booking.');
      return;
    }

    // Validate date (shouldn't be in the past)
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selectedDateTime.isBefore(DateTime(now.year, now.month, now.day))) {
      _showErrorDialog('Please select a future date for booking.');
      return;
    }

    // Validate time selection
    if (selectedStartHour == selectedEndHour && isStartAM == isEndAM) {
      _showErrorDialog('Start time and end time cannot be the same.');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      var options = {
        'key': 'rzp_test_0rwYxZvUXDUeW7',
        'amount': (bookingAmount * 100).toInt(),
        'name': 'Turf Booking',
        'description': 'Booking for ${widget.turfName}',
        'prefill': {
          'contact': userProfile!['phone_number'] ?? '',
          'email': userProfile!['email'] ?? '',
        },
        'theme': {'color': '#452152'},
      };

      setState(() {
        isLoading = false;
      });

      _razorpay.open(options);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error initiating payment: $e');
      _showErrorDialog('Failed to initiate payment. Please try again.');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Success: ${response.paymentId}');

    setState(() {
      isLoading = true;
    });

    // Generate IDs first
    bookingId = generateBookingId();
    teamId = generateTeamId();

    print('Generated Booking ID: $bookingId');
    print('Generated Team ID: $teamId');

    bool bookingSaved = false;
    bool teamSaved = false;
    String? errorMessage;

    try {
      // Save booking data
      print('Attempting to save booking...');
      await _saveBookingToFirestore(response.paymentId!);
      bookingSaved = true;
      print('Booking saved successfully');
    } catch (e) {
      print('Error saving booking: $e');
      errorMessage = 'Failed to save booking details: $e';
    }

    try {
      // Save team data
      print('Attempting to save team...');
      await _saveTeamToFirestore(response.paymentId!);
      teamSaved = true;
      print('Team saved successfully');
    } catch (e) {
      print('Error saving team: $e');
      if (errorMessage == null) {
        errorMessage = 'Failed to save team details: $e';
      } else {
        errorMessage += '\nFailed to save team details: $e';
      }
    }

    setState(() {
      isLoading = false;
    });

    // Show appropriate dialog based on results
    if (bookingSaved && teamSaved) {
      print('Both booking and team saved successfully, showing success popup');
      _showBookingSuccessPopup();
    } else {
      print(
        'Error occurred - Booking saved: $bookingSaved, Team saved: $teamSaved',
      );

      // Verify data was actually saved before showing error
      print('Verifying saved data...');
      bool bookingVerified = await _verifyBookingSaved();
      bool teamVerified = await _verifyTeamSaved();

      print(
        'Verification results - Booking: $bookingVerified, Team: $teamVerified',
      );

      if (bookingVerified && teamVerified) {
        print('Verification successful, showing success popup');
        _showBookingSuccessPopup();
      } else {
        print('Verification failed, showing error dialog');
        _showErrorDialog(
          errorMessage ??
              'Failed to save booking details. Please contact support with Payment ID: ${response.paymentId}',
        );
      }
    }
  }

  Future<bool> _verifyBookingSaved() async {
    try {
      if (bookingId == null || userProfile == null) {
        print('Verification failed: bookingId or userProfile is null');
        return false;
      }

      print(
        'Verifying booking with ID: $bookingId for user: ${userProfile!['uid']}',
      );

      final doc =
          await FirebaseFirestore.instance
              .collection('booking_details')
              .doc(widget.owner_id)
              .collection(userProfile!['uid'])
              .doc(bookingId)
              .get();

      bool exists = doc.exists;
      print('Booking verification result: $exists');

      if (exists) {
        print('Booking data: ${doc.data()}');
      }

      return exists;
    } catch (e) {
      print('Error verifying booking: $e');
      return false;
    }
  }

  Future<bool> _verifyTeamSaved() async {
    try {
      if (teamId == null) {
        print('Verification failed: teamId is null');
        return false;
      }

      print('Verifying team with ID: $teamId');

      final doc =
          await FirebaseFirestore.instance
              .collection('created_team')
              .doc(teamId)
              .get();

      bool exists = doc.exists;
      print('Team verification result: $exists');

      if (exists) {
        print('Team data: ${doc.data()}');
      }

      return exists;
    } catch (e) {
      print('Error verifying team: $e');
      return false;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: ${response.code} - ${response.message}');
    _showErrorDialog('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
  }

  Future<void> _saveBookingToFirestore(String paymentId) async {
    if (userProfile == null || bookingId == null) {
      throw Exception('User profile or booking ID is null');
    }

    print('Saving booking to Firestore...');
    print('User UID: ${userProfile!['uid']}');
    print('Owner ID: ${widget.owner_id}');
    print('Booking ID: $bookingId');

    final bookingData = {
      'booking_id': bookingId,
      'turf_name': widget.turfName,
      'location': widget.location,
      'sport': selectedSport,
      'date':
          '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
      'start_time': formatHour(selectedStartHour, isStartAM),
      'end_time': formatHour(selectedEndHour, isEndAM),
      'slot_time':
          '${formatHour(selectedStartHour, isStartAM)} - ${formatHour(selectedEndHour, isEndAM)}',
      'slot_date':
          '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
      'selected_sport': selectedSport,
      'booked_user_name': userProfile!['name'] ?? 'Unknown',
      'booked_user_id': userProfile!['uid'],
      'owner_id': widget.owner_id,
      'payment_id': paymentId,
      'booking_timestamp': FieldValue.serverTimestamp(),
      'status': 'confirmed',
      'amount': bookingAmount,
      'creator_name': widget.creatorName,
      'total_players': widget.totalPlayers,
      'need_players': widget.needPlayers,
      'team_id': teamId,
    };

    // Validate required fields
    if (selectedSport == null) {
      throw Exception('Sport selection is required');
    }

    print('Booking data to save: $bookingData');

    await FirebaseFirestore.instance
        .collection('booking_details')
        .doc(widget.owner_id)
        .collection(userProfile!['uid'])
        .doc(bookingId)
        .set(bookingData);

    print('Booking data saved successfully to Firestore');
  }

  Future<void> _saveTeamToFirestore(String paymentId) async {
    if (userProfile == null || teamId == null || bookingId == null) {
      throw Exception(
        'Required data (userProfile, teamId, or bookingId) is null',
      );
    }

    print('Saving team to Firestore...');
    print('Team ID: $teamId');

    // Get current server timestamp for the main document
    final currentTimestamp = DateTime.now();

    final teamData = {
      'team_id': teamId,
      'creator_name': widget.creatorName,
      'total_players': widget.totalPlayers,
      'need_players': widget.needPlayers,
      'turf_name': widget.turfName,
      'turf_location': widget.location,
      'slot_time':
          '${formatHour(selectedStartHour, isStartAM)} - ${formatHour(selectedEndHour, isEndAM)}',
      'slot_date':
          '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
      'selected_sport': selectedSport,
      'booking_id': bookingId,
      'owner_id': widget.owner_id,
      'creator_user_id': userProfile!['uid'],
      'payment_id': paymentId,
      'team_timestamp':
          FieldValue.serverTimestamp(), // This is fine for top-level fields
      'status': 'active',
      'amount': bookingAmount,
      'joined_players': [
        {
          'user_id': userProfile!['uid'],
          'user_name': userProfile!['name'] ?? 'Unknown',
          'joined_at':
              currentTimestamp, // Use regular DateTime instead of FieldValue.serverTimestamp()
          'role': 'creator',
        },
      ],
      'available_slots': widget.needPlayers,
    };

    print('Team data to save: $teamData');

    await FirebaseFirestore.instance
        .collection('created_team')
        .doc(teamId)
        .set(teamData);

    print('Team data saved successfully to Firestore');
  }

  void _showBookingSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          spreadRadius: 5,
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Booking Successful!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Your booking for ${widget.turfName} has been confirmed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Team created with ${widget.totalPlayers} total players, needing ${widget.needPlayers} more players.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Booking ID: $bookingId',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Team ID: $teamId',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _generateAndShareBookingPDF();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF452152),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(
                            'Download Receipt',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade500,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateAndShareBookingPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'BOOKING RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Booking Details:',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Booking ID: $bookingId'),
                pw.Text('Team ID: $teamId'),
                pw.Text('Turf Name: ${widget.turfName}'),
                pw.Text('Location: ${widget.location}'),
                pw.Text('Sport: $selectedSport'),
                pw.Text(
                  'Date: ${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
                ),
                pw.Text(
                  'Time: ${formatHour(selectedStartHour, isStartAM)} - ${formatHour(selectedEndHour, isEndAM)}',
                ),
                pw.Text('Amount: ₹$bookingAmount'),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Team Details:',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Creator: ${widget.creatorName}'),
                pw.Text('Total Players: ${widget.totalPlayers}'),
                pw.Text('Players Needed: ${widget.needPlayers}'),
                pw.SizedBox(height: 20),
                pw.Text('Booked by: ${userProfile!['name']}'),
                pw.Text('Contact: ${userProfile!['phone_number']}'),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/booking_receipt_$bookingId.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'Booking Receipt');
    } catch (e) {
      print('Error generating PDF: $e');
      _showErrorDialog('Failed to generate receipt. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.red.shade100],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade300),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade600,
                    size: 48,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
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
            child: SafeArea(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 30),
                    _buildTeamInfoCard(),
                    SizedBox(height: 25),
                    _buildTurfInfoCard(),
                    SizedBox(height: 25),
                    _buildSportSelection(),
                    SizedBox(height: 25),
                    _buildDateSelection(),
                    SizedBox(height: 25),
                    _buildTimeSelection(),
                    SizedBox(height: 40),
                    _buildBookButton(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book Turf &',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback:
                          (bounds) => LinearGradient(
                            colors: [Colors.cyanAccent, Colors.greenAccent],
                          ).createShader(bounds),
                      child: Text(
                        'Create Team',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamInfoCard() {
    return AnimatedBuilder(
      animation: _cardSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.red.shade400],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            spreadRadius: 2,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(Icons.group, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 15),
                    Text(
                      'Team Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _buildInfoRow('Creator', widget.creatorName, Icons.person),
                _buildInfoRow(
                  'Total Players',
                  '${widget.totalPlayers}',
                  Icons.groups,
                ),
                _buildInfoRow(
                  'Need Players',
                  '${widget.needPlayers}',
                  Icons.person_add,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTurfInfoCard() {
    return AnimatedBuilder(
      animation: _cardSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value * 0.5),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.withOpacity(0.25),
                  Colors.blue.withOpacity(0.15),
                  Colors.purple.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.greenAccent.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.teal.shade400],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            spreadRadius: 2,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.sports_soccer,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 15),
                    Text(
                      'Turf Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _buildInfoRow('Turf Name', widget.turfName, Icons.stadium),
                _buildInfoRow('Location', widget.location, Icons.location_on),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSportSelection() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Sport',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children:
                    sports.map((sport) {
                      bool isSelected = selectedSport == sport['name'];
                      return AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: isSelected ? _pulseAnimation.value : 1.0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedSport = sport['name'];
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  gradient:
                                      isSelected
                                          ? LinearGradient(
                                            colors: [
                                              sport['color'],
                                              sport['color'].withOpacity(0.7),
                                            ],
                                          )
                                          : LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.15),
                                              Colors.white.withOpacity(0.08),
                                            ],
                                          ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? sport['color']
                                            : Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: sport['color'].withOpacity(
                                                0.4,
                                              ),
                                              spreadRadius: 3,
                                              blurRadius: 15,
                                            ),
                                          ]
                                          : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      sport['icon'],
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      sport['name'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateSelection() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _fadeAnimation.value) * 50),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated Title with Glow Effect
                ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.purple.shade200,
                          Colors.blue.shade200,
                        ],
                      ).createShader(bounds),
                  child: Text(
                    'Select Date',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Animated underline
                AnimatedContainer(
                  duration: Duration(milliseconds: 800),
                  width: _fadeAnimation.value * 100,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),

                // Main Date Picker Container with Enhanced Design
                AnimatedContainer(
                  duration: Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.purple.withOpacity(0.1),
                        Colors.blue.withOpacity(0.08),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        spreadRadius: 3,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 15,
                        offset: Offset(0, -4),
                      ),
                      // Inner glow effect
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        spreadRadius: -2,
                        blurRadius: 10,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Animated background particles
                            ...List.generate(
                              5,
                              (index) => AnimatedPositioned(
                                duration: Duration(
                                  milliseconds: 2000 + (index * 200),
                                ),
                                curve: Curves.easeInOut,
                                left: _fadeAnimation.value * (index * 60.0),
                                top: _fadeAnimation.value * (index * 20.0),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),

                            // Date Picker Content
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                              child: ScrollDatePicker(
                                selectedDate: _selectedDate,
                                minimumDate: DateTime(DateTime.now().year),
                                maximumDate: DateTime(DateTime.now().year + 10),
                                locale: const Locale('en'),
                                onDateTimeChanged: (DateTime value) {
                                  setState(() {
                                    _selectedDate = value;
                                  });
                                  // Add haptic feedback
                                  HapticFeedback.lightImpact();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 15),

                // Selected Date Display with Animation
                AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.purple.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: Text(
                          DateFormat(
                            'EEEE, MMMM dd, yyyy',
                          ).format(_selectedDate),
                          key: ValueKey(_selectedDate),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildScrollableTimePicker('Start Time', true)),
            SizedBox(width: 20),
            Expanded(child: _buildScrollableTimePicker('End Time', false)),
          ],
        ),
      ],
    );
  }

  Widget _buildScrollableTimePicker(String label, bool isStartTime) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final textScaleFactor = MediaQuery.of(context).textScaleFactor;

        // Device type detection
        final isSmallScreen = screenWidth < 360;
        final isMediumScreen = screenWidth >= 360 && screenWidth < 414;
        final isLargeScreen = screenWidth >= 414;
        final isTablet = screenWidth > 600;

        // Responsive dimensions
        final containerHeight =
            isTablet
                ? 250.0
                : isSmallScreen
                ? 180.0
                : isMediumScreen
                ? 200.0
                : 220.0;

        final headerPadding = isSmallScreen ? 12.0 : 15.0;
        final borderRadius = isSmallScreen ? 20.0 : 25.0;
        final iconSize = (isSmallScreen ? 18.0 : 20.0) / textScaleFactor;
        final headerFontSize = (isSmallScreen ? 14.0 : 16.0) / textScaleFactor;

        // Time picker specific dimensions
        final itemExtent =
            isSmallScreen
                ? 40.0
                : isTablet
                ? 60.0
                : 50.0;
        final selectedFontSize =
            (isSmallScreen
                ? 20.0
                : isTablet
                ? 28.0
                : 24.0) /
            textScaleFactor;
        final unselectedFontSize =
            (isSmallScreen
                ? 16.0
                : isTablet
                ? 20.0
                : 18.0) /
            textScaleFactor;

        // AM/PM button dimensions
        final amPmPadding = EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8.0 : 12.0,
          vertical: isSmallScreen ? 6.0 : 8.0,
        );
        final amPmFontSize = (isSmallScreen ? 12.0 : 14.0) / textScaleFactor;
        final amPmSpacing = isSmallScreen ? 8.0 : 10.0;

        return AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatingAnimation.value * 0.5),
              child: Container(
                height: containerHeight,
                constraints: BoxConstraints(
                  minHeight: 160.0,
                  maxHeight: isTablet ? 300.0 : 250.0,
                ),
                decoration: BoxDecoration(
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
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.purpleAccent.withOpacity(0.4),
                    width: isSmallScreen ? 1.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF452152).withOpacity(0.3),
                      spreadRadius: isSmallScreen ? 1 : 2,
                      blurRadius: isSmallScreen ? 10 : 15,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(headerPadding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF452152).withOpacity(0.9),
                            Color(0xFF3D1A4A),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(borderRadius),
                          topRight: Radius.circular(borderRadius),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isStartTime
                                ? Icons.access_time
                                : Icons.access_time_filled,
                            color: Colors.white,
                            size: iconSize,
                          ),
                          SizedBox(width: isSmallScreen ? 6 : 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: headerFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Time Picker Content
                    Expanded(
                      child: Row(
                        children: [
                          // Hour Picker
                          Expanded(
                            flex: isSmallScreen ? 2 : 2,
                            child: Container(
                              height: double.infinity,
                              child: ListWheelScrollView.useDelegate(
                                itemExtent: itemExtent,
                                perspective: 0.005,
                                diameterRatio: isTablet ? 1.5 : 1.2,
                                physics: FixedExtentScrollPhysics(),
                                controller: FixedExtentScrollController(
                                  initialItem:
                                      (isStartTime
                                          ? selectedStartHour
                                          : selectedEndHour) -
                                      1,
                                ),
                                onSelectedItemChanged: (index) {
                                  // Add haptic feedback
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (isStartTime) {
                                      selectedStartHour = hours[index];
                                    } else {
                                      selectedEndHour = hours[index];
                                    }
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  builder: (context, index) {
                                    if (index < 0 || index >= hours.length)
                                      return null;

                                    bool isSelected =
                                        isStartTime
                                            ? selectedStartHour == hours[index]
                                            : selectedEndHour == hours[index];

                                    return Container(
                                      alignment: Alignment.center,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 4.0 : 8.0,
                                        vertical: 2.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? Colors.white.withOpacity(0.25)
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 8.0 : 10.0,
                                        ),
                                        border:
                                            isSelected
                                                ? Border.all(
                                                  color: Colors.purpleAccent
                                                      .withOpacity(0.6),
                                                  width: 1.5,
                                                )
                                                : null,
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: Color(
                                                      0xFF452152,
                                                    ).withOpacity(0.4),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                                : null,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '${hours[index]}',
                                          style: TextStyle(
                                            color:
                                                isSelected
                                                    ? Colors.purpleAccent
                                                    : Colors.white70,
                                            fontSize:
                                                isSelected
                                                    ? selectedFontSize
                                                    : unselectedFontSize,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            shadows:
                                                isSelected
                                                    ? [
                                                      Shadow(
                                                        color: Colors.black
                                                            .withOpacity(0.3),
                                                        offset: Offset(1, 1),
                                                        blurRadius: 2,
                                                      ),
                                                    ]
                                                    : null,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: hours.length,
                                ),
                              ),
                            ),
                          ),

                          // Divider
                          Container(
                            width: 1,
                            height: double.infinity,
                            margin: EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),

                          // AM/PM Picker
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 4.0 : 8.0,
                                vertical: 20.0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // AM Button
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          if (isStartTime) {
                                            isStartAM = true;
                                          } else {
                                            isEndAM = true;
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        margin: EdgeInsets.only(
                                          bottom: amPmSpacing / 2,
                                        ),
                                        padding: amPmPadding,
                                        decoration: BoxDecoration(
                                          gradient:
                                              (isStartTime
                                                      ? isStartAM
                                                      : isEndAM)
                                                  ? LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Color(
                                                        0xFF452152,
                                                      ).withOpacity(0.8),
                                                      Color(0xFF3D1A4A),
                                                    ],
                                                  )
                                                  : null,
                                          color:
                                              (isStartTime
                                                      ? isStartAM
                                                      : isEndAM)
                                                  ? null
                                                  : Colors.white.withOpacity(
                                                    0.1,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            isSmallScreen ? 10 : 12,
                                          ),
                                          border: Border.all(
                                            color:
                                                (isStartTime
                                                        ? isStartAM
                                                        : isEndAM)
                                                    ? Colors.purpleAccent
                                                    : Colors.white.withOpacity(
                                                      0.3,
                                                    ),
                                          ),
                                          boxShadow:
                                              (isStartTime
                                                      ? isStartAM
                                                      : isEndAM)
                                                  ? [
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFF452152,
                                                      ).withOpacity(0.4),
                                                      blurRadius: 8,
                                                      spreadRadius: 1,
                                                    ),
                                                  ]
                                                  : null,
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'AM',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: amPmFontSize,
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    offset: Offset(1, 1),
                                                    blurRadius: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: amPmSpacing),

                                  // PM Button
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          if (isStartTime) {
                                            isStartAM = false;
                                          } else {
                                            isEndAM = false;
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        margin: EdgeInsets.only(
                                          top: amPmSpacing / 2,
                                        ),
                                        padding: amPmPadding,
                                        decoration: BoxDecoration(
                                          gradient:
                                              !(isStartTime
                                                      ? isStartAM
                                                      : isEndAM)
                                                  ? LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Color(
                                                        0xFF452152,
                                                      ).withOpacity(0.8),
                                                      Color(0xFF3D1A4A),
                                                    ],
                                                  )
                                                  : null,
                                          color:
                                              !(isStartTime
                                                      ? isStartAM
                                                      : isEndAM)
                                                  ? null
                                                  : Colors.white.withOpacity(
                                                    0.1,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            isSmallScreen ? 10 : 12,
                                          ),
                                          border: Border.all(
                                            color:
                                                !(isStartTime
                                                        ? isStartAM
                                                        : isEndAM)
                                                    ? Colors.purpleAccent
                                                    : Colors.white.withOpacity(
                                                      0.3,
                                                    ),
                                          ),
                                          boxShadow:
                                              !(isStartTime
                                                      ? isStartAM
                                                      : isEndAM)
                                                  ? [
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFF452152,
                                                      ).withOpacity(0.4),
                                                      blurRadius: 8,
                                                      spreadRadius: 1,
                                                    ),
                                                  ]
                                                  : null,
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'PM',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: amPmFontSize,
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    offset: Offset(1, 1),
                                                    blurRadius: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final textScaleFactor = MediaQuery.of(context).textScaleFactor;

        // Device type detection
        final isSmallScreen = screenWidth < 360;
        final isMediumScreen = screenWidth >= 360 && screenWidth < 414;
        final isLargeScreen = screenWidth >= 414;
        final isTablet = screenWidth > 600;

        // Responsive dimensions
        final buttonHeight =
            isTablet
                ? 80.0
                : isSmallScreen
                ? 60.0
                : isMediumScreen
                ? 70.0
                : 75.0;

        final borderRadius = buttonHeight / 2; // Keep it perfectly rounded
        final iconSize =
            (isSmallScreen
                ? 20.0
                : isTablet
                ? 28.0
                : 24.0) /
            textScaleFactor;
        final fontSize =
            (isSmallScreen
                ? 16.0
                : isTablet
                ? 20.0
                : 18.0) /
            textScaleFactor;
        final priceBoxFontSize =
            (isSmallScreen
                ? 14.0
                : isTablet
                ? 18.0
                : 16.0) /
            textScaleFactor;

        // Responsive spacing
        final horizontalSpacing = isSmallScreen ? 8.0 : 10.0;
        final loadingSpacing = isSmallScreen ? 12.0 : 15.0;

        // Shadow properties
        final shadowBlurRadius =
            isTablet
                ? 25.0
                : isSmallScreen
                ? 15.0
                : 20.0;
        final shadowSpreadRadius =
            isTablet
                ? 4.0
                : isSmallScreen
                ? 2.0
                : 3.0;
        final shadowOffset = Offset(
          0,
          isTablet
              ? 10.0
              : isSmallScreen
              ? 6.0
              : 8.0,
        );

        // Price box padding
        final priceBoxPadding = EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8.0 : 12.0,
          vertical: isSmallScreen ? 4.0 : 6.0,
        );

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: double.infinity,
                height: buttonHeight,
                constraints: BoxConstraints(
                  minHeight: 50.0,
                  maxHeight: isTablet ? 100.0 : 80.0,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8.0 : 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
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
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.purpleAccent.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF452152).withOpacity(0.5),
                      spreadRadius: shadowSpreadRadius,
                      blurRadius: shadowBlurRadius,
                      offset: shadowOffset,
                    ),
                    // Inner highlight
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      spreadRadius: -2,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(borderRadius),
                    onTap:
                        isLoading
                            ? null
                            : () {
                              HapticFeedback.lightImpact();
                              _initiatePayment();
                            },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16.0 : 20.0,
                        vertical: 8.0,
                      ),
                      child:
                          isLoading
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: iconSize,
                                    height: iconSize,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: isSmallScreen ? 2.5 : 3.0,
                                    ),
                                  ),
                                  SizedBox(width: loadingSpacing),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Processing...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              offset: Offset(1, 1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.sports_soccer,
                                    color: Colors.white,
                                    size: iconSize,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: horizontalSpacing),

                                  // Flexible text that can shrink on small screens
                                  Flexible(
                                    flex: isSmallScreen ? 3 : 2,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        isSmallScreen
                                            ? 'Book & Create Team'
                                            : 'Book Turf & Create Team',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              offset: Offset(1, 1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: horizontalSpacing),

                                  // Price container
                                  Container(
                                    padding: priceBoxPadding,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 12.0 : 15.0,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '₹$bookingAmount',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: priceBoxFontSize,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              offset: Offset(1, 1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 18),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
