import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  // Razorpay and Firestore related variables
  late Razorpay _razorpay;
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  bool isLoading = false;
  Map<String, dynamic>? adminDetails;
  Map<String, dynamic>? userProfile;
  String? bookingId;
  double bookingAmount = 500.0;

  List<String> sports = [
    'Football',
    'Cricket',
    'Basketball',
    'Tennis',
    'Hockey',
    'Pickleball',
  ];

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

    _cardAnimationController.forward();
    _fadeAnimationController.forward();
    _scaleAnimationController.forward();
    _slideAnimationController.forward();
    _bounceAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _pulseAnimationController.dispose();
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
    _slideAnimationController.dispose();
    _bounceAnimationController.dispose();
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
    return AnimatedBuilder(
      animation: _cardSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isSmallScreen = screenWidth < 360;
                final isMediumScreen = screenWidth < 400;

                return _buildModernGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Text(
                        'Select Sport',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 22 : 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Sports Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          crossAxisSpacing: 0,
                          mainAxisSpacing: isSmallScreen ? 12 : 16,
                          childAspectRatio: 4.5,
                        ),
                        itemCount: filteredSports.length,
                        itemBuilder: (context, index) {
                          final sport = filteredSports[index];
                          final isSelected = selectedSport == sport;

                          return TweenAnimationBuilder<double>(
                            duration: Duration(
                              milliseconds: 300 + (index * 50),
                            ),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: Opacity(
                                  opacity: value,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => selectedSport = sport);
                                      if (isSelected) {
                                        _pulseAnimationController
                                            .forward()
                                            .then((_) {
                                              _pulseAnimationController
                                                  .reverse();
                                            });
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 16 : 20,
                                        vertical: isSmallScreen ? 14 : 16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient:
                                            isSelected
                                                ? LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.green.shade400
                                                        .withOpacity(0.8),
                                                    Colors.green.shade600
                                                        .withOpacity(0.8),
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
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? Colors.green.withOpacity(
                                                    0.6,
                                                  )
                                                  : Colors.white.withOpacity(
                                                    0.25,
                                                  ),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: Colors.green
                                                        .withOpacity(0.3),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ]
                                                : [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.05),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                      ),
                                      child: Row(
                                        children: [
                                          // Sport Icon
                                          Container(
                                            padding: EdgeInsets.all(
                                              isSmallScreen ? 8 : 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                          .withOpacity(0.2)
                                                      : Colors.white
                                                          .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: _getSportIcon(
                                              sport,
                                              isSelected,
                                              isSmallScreen,
                                            ),
                                          ),

                                          SizedBox(
                                            width: isSmallScreen ? 12 : 16,
                                          ),

                                          // Sport Name
                                          Expanded(
                                            child: Text(
                                              sport,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight:
                                                    isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                fontSize:
                                                    isSmallScreen ? 16 : 18,
                                                letterSpacing: 0.5,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          // Selection Indicator
                                          if (isSelected)
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              padding: EdgeInsets.all(
                                                isSmallScreen ? 6 : 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Icon(
                                                Icons.check,
                                                color: Colors.green.shade600,
                                                size: isSmallScreen ? 16 : 18,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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

  // Helper method to get sport icons
  Widget _getSportIcon(String sport, bool isSelected, bool isSmallScreen) {
    IconData iconData;
    Color iconColor = Colors.white;

    switch (sport.toLowerCase()) {
      case 'football':
        iconData = Icons.sports_soccer;
        break;
      case 'cricket':
        iconData = Icons.sports_cricket;
        break;
      case 'basketball':
        iconData = Icons.sports_basketball;
        break;
      case 'tennis':
        iconData = Icons.sports_tennis;
        break;
      case 'hockey':
        iconData = Icons.sports_hockey;
        break;
      case 'pickleball':
        iconData = Icons.sports_tennis;
        break;
      default:
        iconData = Icons.sports;
    }

    return Icon(iconData, color: iconColor, size: isSmallScreen ? 20 : 24);
  }

  Widget _buildDateTimeCard() {
    return AnimatedBuilder(
      animation: _cardSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value + 20),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;

                // Define breakpoints for different screen sizes
                final isExtraSmallScreen =
                    screenWidth < 320; // Very small phones
                final isSmallScreen = screenWidth < 360; // Small phones
                final isMediumScreen = screenWidth < 400; // Medium phones
                final isLargeScreen = screenWidth >= 400; // Large phones

                // Dynamic sizing based on screen dimensions
                final horizontalPadding =
                    screenWidth * 0.05; // 5% of screen width
                final cardPadding =
                    isExtraSmallScreen
                        ? 12.0
                        : isSmallScreen
                        ? 16.0
                        : isMediumScreen
                        ? 20.0
                        : 24.0;

                final titleFontSize = screenWidth * 0.06; // 6% of screen width
                final subtitleFontSize =
                    screenWidth * 0.04; // 4% of screen width

                return _buildModernGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Text(
                        'Select Date',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: titleFontSize.clamp(20.0, 26.0),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: cardPadding),

                      // Date Picker Container
                      Container(
                        padding: EdgeInsets.all(cardPadding),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.purple.withOpacity(0.15),
                              Colors.purple.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Date Display
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: cardPadding,
                                vertical: cardPadding * 0.75,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.15),
                                    Colors.white.withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    color: Colors.white,
                                    size: (screenWidth * 0.05).clamp(
                                      16.0,
                                      22.0,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      '${_getWeekday(_selectedDate.weekday)}, ${_getMonthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: subtitleFontSize.clamp(
                                          14.0,
                                          18.0,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: cardPadding),

                            // Date Picker with dynamic height
                            Container(
                              height: (screenHeight * 0.12).clamp(80.0, 120.0),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: ScrollDatePicker(
                                selectedDate: _selectedDate,
                                minimumDate: DateTime(DateTime.now().year),
                                maximumDate: DateTime(DateTime.now().year + 10),
                                locale: Locale('en'),
                                onDateTimeChanged: (DateTime value) {
                                  setState(() {
                                    _selectedDate = value;
                                  });
                                },
                                options: DatePickerOptions(
                                  backgroundColor: Colors.transparent,
                                  itemExtent: (screenHeight * 0.08).clamp(
                                    40.0,
                                    70.0,
                                  ),
                                  diameterRatio: isExtraSmallScreen ? 2.5 : 3.0,
                                  perspective: 0.01,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: cardPadding * 1.2),

                      // Time Section Header
                      Text(
                        'Select Time',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: titleFontSize.clamp(20.0, 26.0),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: cardPadding),

                      // Time Pickers - Responsive Layout
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
    final isExtraSmallScreen = screenWidth < 320;
    final isSmallScreen = screenWidth < 360;

    // For very small screens, stack the time pickers vertically
    if (isExtraSmallScreen) {
      return Column(
        children: [
          _buildTimePickerCard(
            title: 'Start Time',
            icon: Icons.access_time_outlined,
            selectedHour: selectedStartHour,
            isAM: isStartAM,
            color: Colors.green,
            onChanged:
                (hour, isAM) => setState(() {
                  selectedStartHour = hour;
                  isStartAM = isAM;
                }),
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            cardPadding: cardPadding,
          ),
          SizedBox(height: cardPadding),
          _buildTimePickerCard(
            title: 'End Time',
            icon: Icons.access_time_filled_outlined,
            selectedHour: selectedEndHour,
            isAM: isEndAM,
            color: Colors.orange,
            onChanged:
                (hour, isAM) => setState(() {
                  selectedEndHour = hour;
                  isEndAM = isAM;
                }),
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            cardPadding: cardPadding,
          ),
        ],
      );
    }

    // For other screens, use row layout with responsive spacing
    return Row(
      children: [
        Expanded(
          child: _buildTimePickerCard(
            title: 'Start Time',
            icon: Icons.access_time_outlined,
            selectedHour: selectedStartHour,
            isAM: isStartAM,
            color: Colors.green,
            onChanged:
                (hour, isAM) => setState(() {
                  selectedStartHour = hour;
                  isStartAM = isAM;
                }),
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            cardPadding: cardPadding,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : cardPadding * 0.75),
        Expanded(
          child: _buildTimePickerCard(
            title: 'End Time',
            icon: Icons.access_time_filled_outlined,
            selectedHour: selectedEndHour,
            isAM: isEndAM,
            color: Colors.orange,
            onChanged:
                (hour, isAM) => setState(() {
                  selectedEndHour = hour;
                  isEndAM = isAM;
                }),
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            cardPadding: cardPadding,
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerCard({
    required String title,
    required IconData icon,
    required int selectedHour,
    required bool isAM,
    required MaterialColor color,
    required Function(int, bool) onChanged,
    required double screenWidth,
    required double screenHeight,
    required double cardPadding,
  }) {
    final isExtraSmallScreen = screenWidth < 320;
    final isSmallScreen = screenWidth < 360;

    // Dynamic font sizes based on screen width
    final titleFontSize = (screenWidth * 0.035).clamp(12.0, 16.0);
    final timeFontSize = (screenWidth * 0.045).clamp(14.0, 18.0);
    final iconSize = (screenWidth * 0.04).clamp(14.0, 18.0);

    return Container(
      padding: EdgeInsets.all(cardPadding * 0.75),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, color: Colors.white, size: iconSize),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          SizedBox(height: cardPadding * 0.75),

          // Time Display
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: cardPadding * 0.75,
              vertical: cardPadding * 0.5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              formatHour(selectedHour, isAM),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: timeFontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: cardPadding * 0.5),

          // Time Picker with responsive height
          _buildResponsiveTimePicker(
            selectedHour,
            isAM,
            onChanged,
            screenWidth,
            screenHeight,
            cardPadding,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveTimePicker(
    int selectedHour,
    bool isAM,
    Function(int, bool) onChanged,
    double screenWidth,
    double screenHeight,
    double cardPadding,
  ) {
    final isExtraSmallScreen = screenWidth < 320;
    final isSmallScreen = screenWidth < 360;

    // Dynamic dimensions
    final pickerHeight = (screenHeight * 0.15).clamp(100.0, 140.0);
    final itemExtent = (screenHeight * 0.05).clamp(30.0, 45.0);
    final fontSize = (screenWidth * 0.04).clamp(14.0, 18.0);

    return Container(
      height: pickerHeight,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Hour Picker
          Expanded(
            flex: isExtraSmallScreen ? 3 : 2,
            child: ListWheelScrollView.useDelegate(
              itemExtent: itemExtent,
              perspective: 0.005,
              diameterRatio: isExtraSmallScreen ? 1.2 : 1.5,
              physics: const FixedExtentScrollPhysics(),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 12,
                builder: (context, index) {
                  final hour = index + 1;
                  final displayHour = hour == 13 ? 12 : hour;
                  final isSelected = displayHour == selectedHour;
                  return Container(
                    margin: EdgeInsets.symmetric(
                      vertical: 1,
                      horizontal: cardPadding * 0.25,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        displayHour.toString().padLeft(2, '0'),
                        style: GoogleFonts.poppins(
                          fontSize: fontSize,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
              onSelectedItemChanged: (index) {
                final hour = index + 1;
                final displayHour = hour == 13 ? 12 : hour;
                onChanged(displayHour, isAM);
              },
            ),
          ),

          // Separator
          Container(
            width: 1,
            height: pickerHeight * 0.6,
            color: Colors.white.withOpacity(0.2),
          ),

          // AM/PM Picker
          Expanded(
            flex: 1,
            child: ListWheelScrollView.useDelegate(
              itemExtent: itemExtent,
              perspective: 0.005,
              diameterRatio: isExtraSmallScreen ? 1.2 : 1.5,
              physics: const FixedExtentScrollPhysics(),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 2,
                builder: (context, index) {
                  final period = index == 0 ? 'AM' : 'PM';
                  final isSelected = (period == 'AM') == isAM;
                  return Container(
                    margin: EdgeInsets.symmetric(
                      vertical: 1,
                      horizontal: cardPadding * 0.25,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        period,
                        style: GoogleFonts.poppins(
                          fontSize: fontSize * 0.85,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
              onSelectedItemChanged: (index) {
                onChanged(selectedHour, index == 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for date formatting
  String _getWeekday(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
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
    final filteredSports =
        sports
            .where(
              (sport) => sport.toLowerCase().contains(searchText.toLowerCase()),
            )
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
                _buildSportSelectionCard(filteredSports),
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
