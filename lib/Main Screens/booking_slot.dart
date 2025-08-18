import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:intl/intl.dart'; // For DateFormat
import 'dart:ui';

class TimingPage extends StatefulWidget {
  final String turfName;
  final String location;
  final String owner_id;
  const TimingPage({
    super.key,
    required this.owner_id,
    required this.turfName,
    required this.location,
  });

  @override
  State<TimingPage> createState() => _TimingPageState();
}

class _TimingPageState extends State<TimingPage> with TickerProviderStateMixin {
  final List<int> hours = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
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

  bool showSearchField = false;
  String searchText = '';

  // Animation Controllers
  late AnimationController _cardAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _scaleAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _bounceAnimationController;

  late Animation<double> _cardSlideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;
  late AnimationController _floatingAnimationController;
  late Animation<double> _floatingAnimation;

  // Razorpay and Firestore related variables
  late Razorpay _razorpay;
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  bool isLoading = false;
  Map<String, dynamic>? adminDetails;
  Map<String, dynamic>? userProfile;
  String? bookingId;
  double bookingAmount = 500.0;

  final List<Map<String, dynamic>> sports = [
    {'name': 'Football', 'icon': '⚽', 'color': Colors.green},
    {'name': 'Cricket', 'icon': '🏏', 'color': Colors.deepOrange},
    {'name': 'Basketball', 'icon': '🏀', 'color': Colors.redAccent},
    {'name': 'Tennis', 'icon': '🎾', 'color': Colors.pink},
    {'name': 'Hockey', 'icon': '🏒', 'color': Colors.blue},
    {'name': 'Pickleball', 'icon': '🏓', 'color': Colors.purple},
  ];

  Future<bool> _checkForBookingConflicts() async {
    if (selectedSport == null) return false;

    try {
      // Format the selected date to match Firestore format
      final selectedDateString =
          '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}';

      // Convert selected times to 24-hour format for comparison
      final selectedStartTime24 = _convertTo24HourFormat(
        selectedStartHour,
        isStartAM,
      );
      final selectedEndTime24 = _convertTo24HourFormat(
        selectedEndHour,
        isEndAM,
      );

      // Query all bookings for this turf on the selected date
      final QuerySnapshot existingBookings =
          await FirebaseFirestore.instance
              .collectionGroup('booking_details')
              .where('owner_id', isEqualTo: widget.owner_id)
              .where('date', isEqualTo: selectedDateString)
              .where('selected_sport', isEqualTo: selectedSport)
              .where('status', isEqualTo: 'confirmed')
              .get();

      // Check for conflicts with existing bookings
      for (var doc in existingBookings.docs) {
        final bookingData = doc.data() as Map<String, dynamic>;

        // Extract existing booking times and convert to 24-hour format
        final existingStartTime = bookingData['start_time'] as String;
        final existingEndTime = bookingData['end_time'] as String;

        final existingStart24 = _parseTimeString(existingStartTime);
        final existingEnd24 = _parseTimeString(existingEndTime);

        // Check for time overlap
        if (_hasTimeOverlap(
          selectedStartTime24,
          selectedEndTime24,
          existingStart24,
          existingEnd24,
        )) {
          return true; // Conflict found
        }
      }

      return false; // No conflicts
    } catch (e) {
      print('Error checking booking conflicts: $e');
      return false; // Assume no conflict if error occurs
    }
  }

  int _convertTo24HourFormat(int hour, bool isAM) {
    if (hour == 12) {
      return isAM ? 0 : 12;
    } else {
      return isAM ? hour : hour + 12;
    }
  }

  int _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timePart = parts[0];
      final amPm = parts[1];

      final hourMinute = timePart.split(':');
      final hour = int.parse(hourMinute[0]);

      if (amPm.toUpperCase() == 'AM') {
        return hour == 12 ? 0 : hour;
      } else {
        return hour == 12 ? 12 : hour + 12;
      }
    } catch (e) {
      print('Error parsing time string: $timeString, Error: $e');
      return 0;
    }
  }

  // Helper method to check if two time ranges overlap
  bool _hasTimeOverlap(int start1, int end1, int start2, int end2) {
    // Two time ranges overlap if:
    // start1 < end2 AND start2 < end1
    return start1 < end2 && start2 < end1;
  }

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

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bounceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardSlideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideAnimationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bounceAnimationController,
        curve: Curves.bounceOut,
      ),
    );

    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _floatingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _cardAnimationController.forward();
    _fadeAnimationController.forward();
    _scaleAnimationController.forward();
    _slideAnimationController.forward();
    _bounceAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);
    _floatingAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _pulseAnimationController.dispose();
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
    _slideAnimationController.dispose();
    _bounceAnimationController.dispose();
    _floatingAnimationController.dispose();
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

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Success: ${response.paymentId}');

    setState(() {
      isLoading = true;
    });

    try {
      await _saveBookingToFirestore(response.paymentId!);
      _showBookingSuccessPopup();
    } catch (e) {
      print('Error saving booking: $e');
      _showErrorDialog(
        'Failed to save booking details. Please contact support.',
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: ${response.code} - ${response.message}');
    _showErrorDialog('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
  }

  void _showConflictDialog(String conflictMessage) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Container(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width > 600
                      ? 500
                      : double.infinity,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.withOpacity(0.3),
                        Colors.red.withOpacity(0.2),
                        Colors.red.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      width: 1.5,
                      color: Colors.red.withOpacity(0.4),
                    ),
                  ),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Warning Icon with Animation
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade400.withOpacity(0.3),
                                    Colors.red.shade600.withOpacity(0.3),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.6),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.warning_outlined,
                                color: Colors.red.shade300,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 20),

                      // Title
                      Text(
                        'Booking Conflict',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 16),

                      // Conflict Message
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          conflictMessage,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: 24),

                      // Action Buttons
                      Column(
                        children: [
                          // Choose Different Time Button
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade400.withOpacity(0.8),
                                  Colors.blue.shade600.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(25),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  // Optionally scroll to time selection
                                },
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.schedule_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Choose Different Time',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 12),

                          // Close Button
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(25),
                                onTap: () => Navigator.of(context).pop(),
                                child: Center(
                                  child: Text(
                                    'Close',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveBookingToFirestore(String paymentId) async {
    if (userProfile == null) return;

    bookingId = generateBookingId();

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
      'booked_user_name': userProfile!['name'],
      'booked_user_id': userProfile!['uid'],
      'owner_id': widget.owner_id,
      'payment_id': paymentId,
      'booking_timestamp': FieldValue.serverTimestamp(),
      'status': 'confirmed',
      'amount': bookingAmount,
    };

    await FirebaseFirestore.instance
        .collection('booking_details')
        .doc(widget.owner_id)
        .collection(userProfile!['uid'])
        .doc(bookingId)
        .set(bookingData);
  }

  // Enhanced PDF Generation Function
  Future<void> _generateAndShareBookingPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green100,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'BOOKING CONFIRMATION',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green800,
                          ),
                        ),
                        pw.Text(
                          'VOUCHER',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // Booking ID
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      'Booking ID: ${bookingId ?? 'N/A'}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // Booking Details
                  pw.Text(
                    'BOOKING DETAILS',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    children: [
                      _buildPdfTableRow('Turf Name', widget.turfName),
                      _buildPdfTableRow('Location', widget.location),
                      _buildPdfTableRow('Sport', selectedSport ?? 'N/A'),
                      _buildPdfTableRow(
                        'Date',
                        '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
                      ),
                      _buildPdfTableRow(
                        'Time Slot',
                        '${formatHour(selectedStartHour, isStartAM)} - ${formatHour(selectedEndHour, isEndAM)}',
                      ),
                      _buildPdfTableRow(
                        'Amount Paid',
                        '₹${bookingAmount.toStringAsFixed(0)}',
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 20),

                  // Customer Details
                  pw.Text(
                    'CUSTOMER DETAILS',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    children: [
                      _buildPdfTableRow('Name', userProfile?['name'] ?? 'N/A'),
                      _buildPdfTableRow(
                        'Phone',
                        userProfile?['phone_number'] ?? 'N/A',
                      ),
                      _buildPdfTableRow(
                        'Email',
                        userProfile?['email'] ?? 'N/A',
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 30),

                  // Footer
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Thank you for your booking!',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Please arrive 15 minutes before your scheduled time.',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Generated on: ${DateTime.now().toString().split('.')[0]}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Save PDF to device
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/booking_${bookingId ?? 'voucher'}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Booking Confirmation - ${widget.turfName}',
        subject: 'Turf Booking Voucher',
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking voucher downloaded and ready to share!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate booking voucher: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  pw.TableRow _buildPdfTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(value)),
      ],
    );
  }

  Future<void> _initiatePayment() async {
    if (selectedSport == null) {
      _showErrorDialog('Please select a sport');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Check for booking conflicts first
      final hasConflict = await _checkForBookingConflicts();

      if (hasConflict) {
        setState(() {
          isLoading = false;
        });

        // Show conflict dialog with specific message
        final conflictMessage =
            'This time slot (${formatHour(selectedStartHour, isStartAM)} - ${formatHour(selectedEndHour, isEndAM)}) is already booked for ${selectedSport} on ${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}.\n\nPlease select a different time slot.';

        _showConflictDialog(conflictMessage);
        return;
      }

      // If no conflicts, proceed with existing payment logic
      adminDetails = await getAdminDetails(widget.owner_id);

      if (adminDetails == null) {
        _showErrorDialog('Admin details not found. Cannot process payment.');
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (adminDetails!['account_number'] == null ||
          adminDetails!['account_holder_name'] == null ||
          adminDetails!['ifsc_code'] == null) {
        _showErrorDialog(
          'Admin payment details incomplete. Cannot process payment.',
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final options = {
        'key': 'rzp_test_0rwYxZvUXDUeW7',
        'amount': (bookingAmount * 100).toInt(),
        'name': widget.turfName,
        'description': 'Turf Booking - ${selectedSport}',
        'order_id': '',
        'prefill': {
          'contact': userProfile?['phone_number'] ?? '',
          'email': userProfile?['email'] ?? '',
          'name': userProfile?['name'] ?? '',
        },
        'external': {
          'wallets': ['paytm'],
        },
        'theme': {'color': '#563062'},
        'notes': {
          'turf_name': widget.turfName,
          'owner_id': widget.owner_id,
          'sport': selectedSport,
          'date':
              '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
          'time':
              '${formatHour(selectedStartHour, isStartAM)} - ${formatHour(selectedEndHour, isEndAM)}',
          'account_number': adminDetails!['account_number'],
          'account_holder': adminDetails!['account_holder_name'],
          'ifsc_code': adminDetails!['ifsc_code'],
        },
      };

      _razorpay.open(options);
    } catch (e) {
      print('Error initiating payment: $e');
      _showErrorDialog('Failed to initiate payment. Please try again.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Modern Glass Card Widget
  Widget _buildModernGlassCard({
    required Widget child,
    double? height,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    bool addBorder = true,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;
        final isMediumScreen = screenWidth < 400;

        return Container(
          height: height,
          margin: margin ?? EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: padding ?? EdgeInsets.all(isSmallScreen ? 18 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      addBorder
                          ? Border.all(
                            width: 1,
                            color: Colors.white.withOpacity(0.2),
                          )
                          : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  // Enhanced Header Widget
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isSmallScreen = screenWidth < 360;

          return _buildModernGlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    // Back Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 20 : 22,
                        ),
                        splashRadius: 24,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),

                    // Title
                    Expanded(
                      child: Text(
                        'Book Your Slot',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: isSmallScreen ? 22 : 26,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Turf Details Card
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.teal.withOpacity(0.2),
                        Colors.teal.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Turf Icon
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.teal.shade400.withOpacity(0.8),
                                  Colors.teal.shade600.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.sports_soccer_outlined,
                              color: Colors.white,
                              size: isSmallScreen ? 24 : 28,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),

                          // Turf Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Turf Details',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  widget.turfName,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 18 : 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.white70,
                            size: isSmallScreen ? 16 : 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.location,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(opacity: _fadeAnimation, child: child),
        );
      },
    );
  }

  Widget _buildSportSelectionCard(List<String> filteredSports) {
    // Convert filteredSports to match the sports map structure
    final filteredSportsMap =
        sports
            .where((sport) => filteredSports.contains(sport['name']))
            .toList();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;
              final isSmallScreen = screenWidth < 360;
              final isMediumScreen = screenWidth < 400;
              final isLargeScreen = screenWidth >= 600;
              final isTablet = screenWidth >= 768;

              // Calculate responsive grid parameters
              int crossAxisCount;
              double childAspectRatio;
              double crossAxisSpacing;
              double mainAxisSpacing;

              if (isTablet) {
                // Tablet: 4 columns
                crossAxisCount = 4;
                childAspectRatio = 1.1;
                crossAxisSpacing = 20;
                mainAxisSpacing = 20;
              } else if (isLargeScreen) {
                // Large phones: 3 columns
                crossAxisCount = 3;
                childAspectRatio = 1.0;
                crossAxisSpacing = 16;
                mainAxisSpacing = 16;
              } else if (isMediumScreen) {
                // Medium phones: 2 columns
                crossAxisCount = 2;
                childAspectRatio = 0.85;
                crossAxisSpacing = 12;
                mainAxisSpacing = 12;
              } else if (isSmallScreen) {
                // Small phones: 2 columns, more compact
                crossAxisCount = 2;
                childAspectRatio = 0.75;
                crossAxisSpacing = 10;
                mainAxisSpacing = 10;
              } else {
                // Default: 2 columns
                crossAxisCount = 2;
                childAspectRatio = 0.8;
                crossAxisSpacing = 14;
                mainAxisSpacing = 14;
              }

              return _buildModernGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Text(
                      'Select Sport',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize:
                            isSmallScreen
                                ? 20
                                : isTablet
                                ? 28
                                : 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Responsive Sports Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: crossAxisSpacing,
                        mainAxisSpacing: mainAxisSpacing,
                      ),
                      itemCount: filteredSportsMap.length,
                      itemBuilder: (context, index) {
                        final sport = filteredSportsMap[index];
                        final bool isSelected = selectedSport == sport['name'];

                        return AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 300),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutBack,
                              builder: (context, animValue, child) {
                                return Transform.scale(
                                  scale:
                                      isSelected
                                          ? _pulseAnimation.value * animValue
                                          : 1.0 * animValue,
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        selectedSport = sport['name'];
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient:
                                            isSelected
                                                ? LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    sport['color'].withOpacity(
                                                      0.9,
                                                    ),
                                                    sport['color'].withOpacity(
                                                      0.6,
                                                    ),
                                                  ],
                                                )
                                                : LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.white.withOpacity(
                                                      0.15,
                                                    ),
                                                    Colors.white.withOpacity(
                                                      0.08,
                                                    ),
                                                  ],
                                                ),
                                        borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 18 : 22,
                                        ),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? sport['color'].withOpacity(
                                                    0.8,
                                                  )
                                                  : Colors.white.withOpacity(
                                                    0.3,
                                                  ),
                                          width: isSelected ? 2.5 : 1.5,
                                        ),
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: sport['color']
                                                        .withOpacity(0.4),
                                                    spreadRadius: 2,
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    spreadRadius: 1,
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                                : [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            isSmallScreen ? 18 : 22,
                                          ),
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            setState(() {
                                              selectedSport = sport['name'];
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(
                                              isSmallScreen
                                                  ? 12
                                                  : isTablet
                                                  ? 20
                                                  : 16,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                // Sport Icon
                                                Container(
                                                  padding: EdgeInsets.all(
                                                    isSmallScreen
                                                        ? 8
                                                        : isTablet
                                                        ? 12
                                                        : 10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                                .withOpacity(
                                                                  0.2,
                                                                )
                                                            : Colors.white
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                    shape: BoxShape.circle,
                                                    border:
                                                        isSelected
                                                            ? Border.all(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                            )
                                                            : null,
                                                  ),
                                                  child: Text(
                                                    sport['icon'],
                                                    style: TextStyle(
                                                      fontSize:
                                                          isSmallScreen
                                                              ? 20
                                                              : isTablet
                                                              ? 32
                                                              : 26,
                                                    ),
                                                  ),
                                                ),

                                                SizedBox(
                                                  height:
                                                      isSmallScreen ? 8 : 12,
                                                ),

                                                // Sport Name
                                                Flexible(
                                                  child: Text(
                                                    sport['name'],
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight.w600,
                                                      fontSize:
                                                          isSmallScreen
                                                              ? 12
                                                              : isTablet
                                                              ? 18
                                                              : 14,
                                                      letterSpacing: 0.5,
                                                      shadows:
                                                          isSelected
                                                              ? [
                                                                Shadow(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                        0.3,
                                                                      ),
                                                                  offset:
                                                                      const Offset(
                                                                        0,
                                                                        1,
                                                                      ),
                                                                  blurRadius: 2,
                                                                ),
                                                              ]
                                                              : null,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),

                                                // Selection Indicator
                                                if (isSelected)
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          top: 6,
                                                        ),
                                                    child: Icon(
                                                      Icons.check_circle,
                                                      color: Colors.white,
                                                      size:
                                                          isSmallScreen
                                                              ? 16
                                                              : 20,
                                                    ),
                                                  ),
                                              ],
                                            ),
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
                      },
                    ),

                    // Optional: Add search functionality for large lists
                    if (sports.length > 8) ...[
                      SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.white70, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    searchText = value;
                                  });
                                },
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search sports...',
                                  hintStyle: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (searchText.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    searchText = '';
                                  });
                                },
                                child: Icon(
                                  Icons.clear,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDateTimeCard() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _fadeAnimation.value) * 50),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;
                final textScaleFactor = MediaQuery.of(context).textScaleFactor;

                // Define breakpoints for different screen sizes
                final isExtraSmallScreen =
                    screenWidth < 320; // Very small phones
                final isSmallScreen = screenWidth < 360; // Small phones
                final isMediumScreen = screenWidth < 400; // Medium phones
                final isLargeScreen = screenWidth < 600; // Large phones
                final isTablet = screenWidth >= 600; // Tablets

                // Dynamic sizing based on screen dimensions
                final cardPadding =
                    isExtraSmallScreen
                        ? 12.0
                        : isSmallScreen
                        ? 16.0
                        : isMediumScreen
                        ? 20.0
                        : 24.0;

                final titleFontSize = (screenWidth * 0.06).clamp(18.0, 28.0);

                return _buildModernGlassCard(
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
                            fontSize: titleFontSize,
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
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 120,
                          maxHeight: isTablet ? 180 : 150,
                        ),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          width: double.infinity,
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
                            borderRadius: BorderRadius.circular(
                              isExtraSmallScreen ? 20 : 30,
                            ),
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
                            borderRadius: BorderRadius.circular(
                              isExtraSmallScreen ? 18 : 28,
                            ),
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
                                        left:
                                            _fadeAnimation.value *
                                            (index * 60.0),
                                        top:
                                            _fadeAnimation.value *
                                            (index * 20.0),
                                        child: Container(
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Date Picker Content
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isExtraSmallScreen ? 8 : 16,
                                        vertical: isExtraSmallScreen ? 8 : 12,
                                      ),
                                      child: ScrollDatePicker(
                                        selectedDate: _selectedDate,
                                        minimumDate: DateTime(
                                          DateTime.now().year,
                                        ),
                                        maximumDate: DateTime(
                                          DateTime.now().year + 10,
                                        ),
                                        locale: const Locale('en'),
                                        onDateTimeChanged: (DateTime value) {
                                          setState(() {
                                            _selectedDate = value;
                                          });
                                          // Add haptic feedback
                                          HapticFeedback.lightImpact();
                                        },
                                        options: DatePickerOptions(
                                          backgroundColor: Colors.transparent,
                                          itemExtent:
                                              isExtraSmallScreen
                                                  ? 35.0
                                                  : isSmallScreen
                                                  ? 40.0
                                                  : isTablet
                                                  ? 60.0
                                                  : 50.0,
                                          diameterRatio:
                                              isExtraSmallScreen
                                                  ? 2.2
                                                  : isSmallScreen
                                                  ? 2.5
                                                  : 3.0,
                                          perspective: 0.01,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 15),

                      // Selected Date Display with Animation - Responsive
                      AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isExtraSmallScreen ? 12 : 16,
                          vertical: isExtraSmallScreen ? 8 : 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.purple.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            isExtraSmallScreen ? 15 : 20,
                          ),
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
                              size: isExtraSmallScreen ? 14 : 16,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                child: Text(
                                  DateFormat(
                                    isExtraSmallScreen
                                        ? 'MMM dd, yyyy' // Shorter format for small screens
                                        : 'EEEE, MMMM dd, yyyy',
                                  ).format(_selectedDate),
                                  key: ValueKey(_selectedDate),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize:
                                        isExtraSmallScreen
                                            ? 12
                                            : isSmallScreen
                                            ? 13
                                            : 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: cardPadding * 1.2),

                      // Time Section Header
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
                          'Select Time',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),

                      // Animated underline for time
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

                      SizedBox(height: cardPadding),

                      // Use the new responsive time pickers
                      _buildResponsiveTimePickers(
                        screenWidth,
                        screenHeight,
                        cardPadding,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveTimePickers(
    double screenWidth,
    double screenHeight,
    double cardPadding,
  ) {
    // Always use vertical stacked layout for consistent experience across all devices
    return Column(
      children: [
        _buildStackedTimePicker('Start Time', true, screenWidth, screenHeight),
        SizedBox(height: cardPadding),
        _buildStackedTimePicker('End Time', false, screenWidth, screenHeight),
      ],
    );
  }

  Widget _buildStackedTimePicker(
    String label,
    bool isStartTime,
    double screenWidth,
    double screenHeight,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaleFactor = MediaQuery.of(context).textScaleFactor;

        // Comprehensive screen size detection
        final isExtraSmallScreen = screenWidth < 320; // iPhone 5s
        final isSmallScreen = screenWidth < 360; // iPhone SE
        final isMediumScreen = screenWidth < 400; // iPhone 12 mini
        final isLargeScreen = screenWidth < 500; // Most modern phones
        final isTablet = screenWidth >= 600; // Tablets

        // Responsive container dimensions
        final containerHeight =
            isExtraSmallScreen
                ? 200.0
                : isSmallScreen
                ? 220.0
                : isMediumScreen
                ? 240.0
                : isLargeScreen
                ? 260.0
                : 300.0; // Tablet

        // Dynamic sizing
        final headerPadding = (screenWidth * 0.03).clamp(12.0, 18.0);
        final borderRadius = (screenWidth * 0.045).clamp(16.0, 24.0);
        final contentPadding = (screenWidth * 0.025).clamp(12.0, 18.0);

        // Typography scaling
        final iconSize =
            (screenWidth * 0.05).clamp(18.0, 26.0) / textScaleFactor;
        final headerFontSize =
            (screenWidth * 0.038).clamp(14.0, 20.0) / textScaleFactor;

        // Hour picker dimensions
        final hourPickerHeight = containerHeight * 0.75; // 75% for hour picker
        final itemExtent = (hourPickerHeight * 0.25).clamp(35.0, 55.0);
        final selectedFontSize =
            (screenWidth * 0.055).clamp(18.0, 28.0) / textScaleFactor;
        final unselectedFontSize =
            (screenWidth * 0.042).clamp(15.0, 22.0) / textScaleFactor;

        // AM/PM button dimensions - these need to be LARGE and VISIBLE
        final amPmButtonWidth = (screenWidth * 0.18).clamp(60.0, 95.0);
        final amPmButtonHeight = (containerHeight * 0.18).clamp(38.0, 55.0);
        final amPmFontSize =
            (screenWidth * 0.035).clamp(13.0, 20.0) / textScaleFactor;
        final amPmSpacing = (containerHeight * 0.04).clamp(8.0, 15.0);

        return AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatingAnimation.value * 0.5),
              child: Container(
                height: containerHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF452152).withOpacity(0.95),
                      Color(0xFF3D1A4A).withOpacity(0.9),
                      Color(0xFF200D28).withOpacity(0.85),
                      Color(0xFF1B0723).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.purpleAccent.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF452152).withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with icon and title
                    Container(
                      padding: EdgeInsets.all(headerPadding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF563062).withOpacity(0.8),
                            Color(0xFF452152).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(borderRadius - 2),
                          topRight: Radius.circular(borderRadius - 2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.schedule_outlined,
                              color: Colors.white.withOpacity(0.9),
                              size: iconSize,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: headerFontSize,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main content area
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(contentPadding),
                        child: Row(
                          children: [
                            // Hour picker section (left side)
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: itemExtent,
                                    perspective: 0.003,
                                    diameterRatio: 1.8,
                                    physics: FixedExtentScrollPhysics(),
                                    controller: FixedExtentScrollController(
                                      initialItem:
                                          (isStartTime
                                              ? selectedStartHour
                                              : selectedEndHour) -
                                          1,
                                    ),
                                    onSelectedItemChanged: (index) {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        if (isStartTime) {
                                          selectedStartHour = hours[index];
                                        } else {
                                          selectedEndHour = hours[index];
                                        }
                                      });
                                    },
                                    childDelegate:
                                        ListWheelChildBuilderDelegate(
                                          builder: (context, index) {
                                            if (index < 0 ||
                                                index >= hours.length)
                                              return null;

                                            bool isSelected =
                                                isStartTime
                                                    ? selectedStartHour ==
                                                        hours[index]
                                                    : selectedEndHour ==
                                                        hours[index];

                                            return Container(
                                              alignment: Alignment.center,
                                              margin: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient:
                                                    isSelected
                                                        ? LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end:
                                                              Alignment
                                                                  .bottomRight,
                                                          colors: [
                                                            Color(
                                                              0xFFAB47BC,
                                                            ), // Purple
                                                            Color(
                                                              0xFF8E24AA,
                                                            ), // Darker purple
                                                          ],
                                                        )
                                                        : null,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                boxShadow:
                                                    isSelected
                                                        ? [
                                                          BoxShadow(
                                                            color: Color(
                                                              0xFFAB47BC,
                                                            ).withOpacity(0.4),
                                                            blurRadius: 8,
                                                            offset: Offset(
                                                              0,
                                                              2,
                                                            ),
                                                          ),
                                                        ]
                                                        : [],
                                              ),
                                              child: Text(
                                                '${hours[index]}',
                                                style: GoogleFonts.poppins(
                                                  color:
                                                      isSelected
                                                          ? Colors.white
                                                          : Colors.white
                                                              .withOpacity(0.6),
                                                  fontSize:
                                                      isSelected
                                                          ? selectedFontSize
                                                          : unselectedFontSize,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          },
                                          childCount: hours.length,
                                        ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: contentPadding),

                            // AM/PM section (right side) - LARGE AND VISIBLE
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  // Large AM Button
                                  Expanded(
                                    child: _buildClearAMPMButton(
                                      'AM',
                                      isStartTime ? isStartAM : isEndAM,
                                      () {
                                        HapticFeedback.mediumImpact();
                                        setState(() {
                                          if (isStartTime) {
                                            isStartAM = true;
                                          } else {
                                            isEndAM = true;
                                          }
                                        });
                                      },
                                      amPmButtonWidth,
                                      amPmFontSize,
                                      Colors.pinkAccent,
                                      Colors.pinkAccent,
                                      screenWidth,
                                    ),
                                  ),

                                  SizedBox(height: amPmSpacing),

                                  // Large PM Button
                                  Expanded(
                                    child: _buildClearAMPMButton(
                                      'PM',
                                      !(isStartTime ? isStartAM : isEndAM),
                                      () {
                                        HapticFeedback.mediumImpact();
                                        setState(() {
                                          if (isStartTime) {
                                            isStartAM = false;
                                          } else {
                                            isEndAM = false;
                                          }
                                        });
                                      },
                                      amPmButtonWidth,
                                      amPmFontSize,
                                      // Blue colors for PM
                                      Color(0xFF5C6BC0),
                                      Color(0xFF3949AB),
                                      screenWidth,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildClearAMPMButton(
    String text,
    bool isSelected,
    VoidCallback onTap,
    double buttonWidth,
    double fontSize,
    Color selectedColor,
    Color selectedBorder,
    double screenWidth,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: buttonWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          // Solid colors for maximum visibility
          color: isSelected ? selectedColor : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? selectedBorder : Colors.white.withOpacity(0.3),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: selectedColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              alignment: Alignment.center,
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard() {
    return AnimatedBuilder(
      animation: _cardSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value + 40),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isSmallScreen = screenWidth < 360;

                return _buildModernGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Text(
                        'Booking Summary',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 22 : 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Summary Details
                      _buildSummaryRow('Turf', widget.turfName, isSmallScreen),
                      _buildSummaryRow(
                        'Location',
                        widget.location,
                        isSmallScreen,
                      ),
                      _buildSummaryRow(
                        'Sport',
                        selectedSport ?? 'Not selected',
                        isSmallScreen,
                      ),
                      _buildSummaryRow(
                        'Date',
                        '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
                        isSmallScreen,
                      ),
                      _buildSummaryRow(
                        'Time',
                        '${formatHour(selectedStartHour, isStartAM)} - ${formatHour(selectedEndHour, isEndAM)}',
                        isSmallScreen,
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Amount Container
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green.withOpacity(0.2),
                              Colors.green.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '₹${bookingAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade300,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // Book Now Button
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale:
                                selectedSport != null
                                    ? _pulseAnimation.value
                                    : 1.0,
                            child: Container(
                              width: double.infinity,
                              height: isSmallScreen ? 54 : 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors:
                                      selectedSport != null
                                          ? [
                                            Colors.green.shade400.withOpacity(
                                              0.9,
                                            ),
                                            Colors.green.shade600.withOpacity(
                                              0.9,
                                            ),
                                          ]
                                          : [
                                            Colors.white.withOpacity(0.15),
                                            Colors.white.withOpacity(0.08),
                                          ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color:
                                      selectedSport != null
                                          ? Colors.green.withOpacity(0.6)
                                          : Colors.white.withOpacity(0.3),
                                ),
                                boxShadow:
                                    selectedSport != null
                                        ? [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(
                                              0.4,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ]
                                        : [],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap:
                                      selectedSport != null && !isLoading
                                          ? _initiatePayment
                                          : null,
                                  child: Center(
                                    child:
                                        isLoading
                                            ? SizedBox(
                                              width: isSmallScreen ? 20 : 24,
                                              height: isSmallScreen ? 20 : 24,
                                              child:
                                                  const CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                    strokeWidth: 2,
                                                  ),
                                            )
                                            : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.payment_outlined,
                                                  color: Colors.white,
                                                  size: isSmallScreen ? 20 : 24,
                                                ),
                                                SizedBox(
                                                  width: isSmallScreen ? 8 : 12,
                                                ),
                                                Text(
                                                  'Pay & Book Now',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize:
                                                        isSmallScreen ? 16 : 18,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
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
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmallScreen ? 80 : 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatHour(int hour, bool isAM) {
    return '${hour.toString().padLeft(2, '0')}:00 ${isAM ? 'AM' : 'PM'}';
  }

  // Enhanced Success Popup with Modern Design
  void _showBookingSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenWidth < 360;
            final isExtraSmallScreen = screenWidth < 320;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isExtraSmallScreen ? 12 : 20,
                vertical: 30,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.85,
                  maxWidth: screenWidth > 600 ? 500 : double.infinity,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          width: 1.5,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Success Animation
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1200),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      isSmallScreen ? 16 : 20,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade400.withOpacity(
                                            0.3,
                                          ),
                                          Colors.green.shade600.withOpacity(
                                            0.3,
                                          ),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.6),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.4),
                                          blurRadius: 25,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green.shade300,
                                      size: isSmallScreen ? 48 : 56,
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: isSmallScreen ? 20 : 24),

                            // Success Title
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 800),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: Text(
                                      'Booking Confirmed! 🎉',
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallScreen ? 22 : 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Booking Details Card
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1000),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 40 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(
                                        isSmallScreen ? 16 : 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.25),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Booking ID
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(
                                              isSmallScreen ? 12 : 14,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.blue.withOpacity(0.3),
                                                  Colors.blue.withOpacity(0.2),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.blue.withOpacity(
                                                  0.4,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .confirmation_number_outlined,
                                                  color: Colors.blue.shade300,
                                                  size: isSmallScreen ? 16 : 18,
                                                ),
                                                SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    'ID: ${bookingId ?? 'N/A'}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize:
                                                          isSmallScreen
                                                              ? 14
                                                              : 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(
                                            height: isSmallScreen ? 16 : 20,
                                          ),

                                          // Booking Details
                                          ..._buildAnimatedDetailRows(
                                            isSmallScreen,
                                          ),

                                          SizedBox(
                                            height: isSmallScreen ? 12 : 16,
                                          ),

                                          // Amount Container
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(
                                              isSmallScreen ? 12 : 16,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.green.shade400
                                                      .withOpacity(0.25),
                                                  Colors.green.shade600
                                                      .withOpacity(0.25),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.green.withOpacity(
                                                  0.4,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Amount Paid',
                                                  style: GoogleFonts.poppins(
                                                    fontSize:
                                                        isSmallScreen ? 16 : 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${bookingAmount.toStringAsFixed(0)}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize:
                                                        isSmallScreen ? 18 : 22,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.green.shade300,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: isSmallScreen ? 20 : 24),

                            // Action Buttons
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1200),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 50 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: Column(
                                      children: [
                                        // Download Voucher Button
                                        _buildAnimatedButton(
                                          width: double.infinity,
                                          height: isSmallScreen ? 48 : 54,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade400.withOpacity(
                                                0.9,
                                              ),
                                              Colors.blue.shade600.withOpacity(
                                                0.9,
                                              ),
                                            ],
                                          ),
                                          borderColor: Colors.blue.withOpacity(
                                            0.6,
                                          ),
                                          shadowColor: Colors.blue.withOpacity(
                                            0.4,
                                          ),
                                          icon: Icons.download_outlined,
                                          text: 'Download Voucher',
                                          fontSize: isSmallScreen ? 16 : 18,
                                          iconSize: isSmallScreen ? 20 : 22,
                                          onTap: () async {
                                            Navigator.of(context).pop();
                                            await _generateAndShareBookingPDF();
                                          },
                                          isSmallScreen: isSmallScreen,
                                        ),

                                        SizedBox(
                                          height: isSmallScreen ? 12 : 16,
                                        ),

                                        // Back to Home Button
                                        _buildAnimatedButton(
                                          width: double.infinity,
                                          height: isSmallScreen ? 48 : 54,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.25),
                                              Colors.white.withOpacity(0.15),
                                            ],
                                          ),
                                          borderColor: Colors.white.withOpacity(
                                            0.4,
                                          ),
                                          shadowColor: Colors.black.withOpacity(
                                            0.1,
                                          ),
                                          icon: Icons.home_outlined,
                                          text: 'Back to Home',
                                          fontSize: isSmallScreen ? 16 : 18,
                                          iconSize: isSmallScreen ? 20 : 22,
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                          },
                                          isSmallScreen: isSmallScreen,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Footer Message
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1400),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeIn,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      isSmallScreen ? 12 : 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.15),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Thank you for your booking! 🙏',
                                          style: GoogleFonts.poppins(
                                            fontSize: isSmallScreen ? 14 : 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            height: 1.3,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Please arrive 15 minutes before your slot time.',
                                          style: GoogleFonts.poppins(
                                            fontSize: isSmallScreen ? 12 : 14,
                                            color: Colors.white70,
                                            height: 1.3,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
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

  // Helper method to build animated detail rows
  List<Widget> _buildAnimatedDetailRows(bool isSmallScreen) {
    final List<Map<String, String>> details = [
      {'label': 'Turf', 'value': widget.turfName},
      {'label': 'Location', 'value': widget.location},
      {'label': 'Sport', 'value': selectedSport ?? 'N/A'},
      {
        'label': 'Date',
        'value':
            '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
      },
      {
        'label': 'Time Slot',
        'value':
            '${formatHour(selectedStartHour, isStartAM)} - ${formatHour(selectedEndHour, isEndAM)}',
      },
    ];

    return details.asMap().entries.map((entry) {
      final index = entry.key;
      final detail = entry.value;

      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 800 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: Opacity(
              opacity: value,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: isSmallScreen ? 80 : 100,
                      child: Text(
                        detail['label']!,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 13 : 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        detail['value']!,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  // Enhanced animated button widget
  Widget _buildAnimatedButton({
    required double width,
    required double height,
    required Gradient gradient,
    required Color borderColor,
    required Color shadowColor,
    required IconData icon,
    required String text,
    required double fontSize,
    required double iconSize,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: iconSize),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Flexible(
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter sports based on search text
    final filteredSportsNames =
        sports
            .where(
              (sport) => sport['name'].toString().toLowerCase().contains(
                searchText.toLowerCase(),
              ),
            )
            .map((sport) => sport['name'] as String)
            .toList();

    return Scaffold(
      body: Container(
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
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 360 ? 16 : 20,
              vertical: 16,
            ),
            child: Column(
              children: [
                _buildHeader(),
                _buildSportSelectionCard(filteredSportsNames),
                _buildDateTimeCard(),
                _buildBookingCard(),
                SizedBox(
                  height: MediaQuery.of(context).size.width < 360 ? 24 : 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Animation<double>>(
        '_scaleAnimation',
        _scaleAnimation,
      ),
    );
    properties.add(
      DiagnosticsProperty<Animation<double>>('_fadeAnimation', _fadeAnimation),
    );
    properties.add(
      DiagnosticsProperty<Animation<double>>(
        '_pulseAnimation',
        _pulseAnimation,
      ),
    );
    properties.add(
      DiagnosticsProperty<Animation<double>>(
        '_cardSlideAnimation',
        _cardSlideAnimation,
      ),
    );
    properties.add(
      DiagnosticsProperty<Animation<Offset>>(
        '_slideAnimation',
        _slideAnimation,
      ),
    );
    properties.add(
      DiagnosticsProperty<Animation<double>>(
        '_bounceAnimation',
        _bounceAnimation,
      ),
    );
  }
}
