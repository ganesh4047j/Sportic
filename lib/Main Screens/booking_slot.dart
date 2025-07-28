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

  late Animation<double> _cardSlideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _cardSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _cardAnimationController.forward();
    _fadeAnimationController.forward();
    _scaleAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _pulseAnimationController.dispose();
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
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

  // Responsive Glass Card Widget
  Widget _buildGlassContainer({
    required Widget child,
    double? height,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          margin:
              margin ??
              EdgeInsets.only(bottom: constraints.maxWidth < 400 ? 12 : 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              constraints.maxWidth < 400 ? 16 : 24,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding:
                    padding ??
                    EdgeInsets.all(constraints.maxWidth < 400 ? 16 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                    constraints.maxWidth < 400 ? 16 : 24,
                  ),
                  border: Border.all(
                    width: 1.5,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  // Responsive Header Widget
  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;

        return _buildGlassContainer(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 24),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Text(
                      'Book ${widget.turfName}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: isSmallScreen ? 20 : 24,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: isSmallScreen ? 14 : 16,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Flexible(
                      child: Text(
                        widget.location,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildSportSearchCard(List<String> filteredSports) {
    return AnimatedBuilder(
      animation: _cardSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                final crossAxisCount =
                    constraints.maxWidth < 300
                        ? 1
                        : constraints.maxWidth < 500
                        ? 2
                        : 3;

                return _buildGlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade400.withOpacity(0.8),
                                  Colors.blue.shade600.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.sports_soccer,
                              color: Colors.white,
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          Expanded(
                            child: Text(
                              'Select Your Sport',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      if (showSearchField)
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 300),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: TextField(
                                  onChanged:
                                      (value) =>
                                          setState(() => searchText = value),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '🔍 Search sports...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(
                                      isSmallScreen ? 12 : 16,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      if (showSearchField)
                        SizedBox(height: isSmallScreen ? 12 : 16),

                      // Responsive sports grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: filteredSports.length,
                        itemBuilder: (context, index) {
                          final sport = filteredSports[index];
                          final isSelected = selectedSport == sport;

                          return TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 200),
                            tween: Tween(begin: 0.8, end: 1.0),
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => selectedSport = sport);
                                    if (isSelected) {
                                      _pulseAnimationController.forward().then((
                                        _,
                                      ) {
                                        _pulseAnimationController.reverse();
                                      });
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 16,
                                      vertical: isSmallScreen ? 8 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient:
                                          isSelected
                                              ? LinearGradient(
                                                colors: [
                                                  Colors.green.shade400
                                                      .withOpacity(0.8),
                                                  Colors.green.shade600
                                                      .withOpacity(0.8),
                                                ],
                                              )
                                              : LinearGradient(
                                                colors: [
                                                  Colors.white.withOpacity(0.2),
                                                  Colors.white.withOpacity(0.1),
                                                ],
                                              ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Colors.green.withOpacity(0.5)
                                                : Colors.white.withOpacity(0.3),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              isSelected
                                                  ? Colors.green.withOpacity(
                                                    0.4,
                                                  )
                                                  : Colors.black.withOpacity(
                                                    0.1,
                                                  ),
                                          blurRadius: isSelected ? 12 : 6,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: isSmallScreen ? 16 : 18,
                                          ),
                                        if (isSelected)
                                          SizedBox(
                                            width: isSmallScreen ? 6 : 8,
                                          ),
                                        Flexible(
                                          child: Text(
                                            sport,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                              fontSize: isSmallScreen ? 14 : 16,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      Center(
                        child: TextButton.icon(
                          onPressed:
                              () => setState(
                                () => showSearchField = !showSearchField,
                              ),
                          icon: Icon(
                            showSearchField
                                ? Icons.keyboard_arrow_up
                                : Icons.search,
                            color: Colors.white70,
                            size: isSmallScreen ? 18 : 20,
                          ),
                          label: Text(
                            showSearchField ? 'Hide Search' : 'Search Sports',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
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
                final isSmallScreen = constraints.maxWidth < 500;

                return _buildGlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade400.withOpacity(0.8),
                                  Colors.purple.shade600.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          Expanded(
                            child: Text(
                              'Select Date & Time',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Date Picker
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📅 Select Date',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Container(
                              height: isSmallScreen ? 70 : 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
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
                                  itemExtent: isSmallScreen ? 50 : 60,
                                  diameterRatio: 3,
                                  perspective: 0.01,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Time Pickers
                      isSmallScreen
                          ? Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🕐 Start Time',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildScrollableTimePicker(
                                      selectedStartHour,
                                      isStartAM,
                                      Colors.green,
                                      (hour, isAM) => setState(() {
                                        selectedStartHour = hour;
                                        isStartAM = isAM;
                                      }),
                                      isSmallScreen: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🕐 End Time',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildScrollableTimePicker(
                                      selectedEndHour,
                                      isEndAM,
                                      Colors.orange,
                                      (hour, isAM) => setState(() {
                                        selectedEndHour = hour;
                                        isEndAM = isAM;
                                      }),
                                      isSmallScreen: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                          : Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '🕐 Start Time',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildScrollableTimePicker(
                                        selectedStartHour,
                                        isStartAM,
                                        Colors.green,
                                        (hour, isAM) => setState(() {
                                          selectedStartHour = hour;
                                          isStartAM = isAM;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '🕐 End Time',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildScrollableTimePicker(
                                        selectedEndHour,
                                        isEndAM,
                                        Colors.orange,
                                        (hour, isAM) => setState(() {
                                          selectedEndHour = hour;
                                          isEndAM = isAM;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildScrollableTimePicker(
    int selectedHour,
    bool isAM,
    MaterialColor color,
    Function(int, bool) onChanged, {
    bool isSmallScreen = false,
  }) {
    final FixedExtentScrollController hourController =
        FixedExtentScrollController(
          initialItem: selectedHour == 12 ? 0 : selectedHour - 1,
        );
    final FixedExtentScrollController ampmController =
        FixedExtentScrollController(initialItem: isAM ? 0 : 1);

    final double pickerHeight = isSmallScreen ? 120 : 140;
    final double itemExtent = isSmallScreen ? 40 : 50;
    final double fontSize = isSmallScreen ? 18 : 20;

    return Container(
      height: pickerHeight,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Hour Picker
            Expanded(
              flex: 2,
              child: ListWheelScrollView.useDelegate(
                controller: hourController,
                itemExtent: itemExtent,
                perspective: 0.005,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 12,
                  builder: (context, index) {
                    final hour = index + 1 == 13 ? 12 : (index + 1) % 13;
                    final displayHour = hour == 0 ? 12 : hour;
                    final isSelected = displayHour == selectedHour;
                    return Container(
                      margin: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 3 : 5,
                        horizontal: isSmallScreen ? 6 : 8,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 6 : 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            isSelected
                                ? Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                )
                                : null,
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
                  final hour = index + 1 == 13 ? 12 : (index + 1) % 13;
                  final displayHour = hour == 0 ? 12 : hour;
                  onChanged(displayHour, isAM);
                },
              ),
            ),

            // Separator
            Container(
              width: 1,
              height: pickerHeight * 0.5,
              color: Colors.white.withOpacity(0.3),
            ),

            // AM/PM Picker
            Expanded(
              flex: 1,
              child: ListWheelScrollView.useDelegate(
                controller: ampmController,
                itemExtent: itemExtent,
                perspective: 0.005,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 2,
                  builder: (context, index) {
                    final period = index == 0 ? 'AM' : 'PM';
                    final isSelected = (period == 'AM') == isAM;
                    return Container(
                      margin: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 3 : 5,
                        horizontal: isSmallScreen ? 6 : 8,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12,
                        vertical: isSmallScreen ? 6 : 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            isSelected
                                ? Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                )
                                : null,
                      ),
                      child: Center(
                        child: Text(
                          period,
                          style: GoogleFonts.poppins(
                            fontSize: fontSize - 2,
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
                final isSmallScreen = constraints.maxWidth < 400;

                return _buildGlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400.withOpacity(0.8),
                                  Colors.green.shade600.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              color: Colors.white,
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          Expanded(
                            child: Text(
                              'Booking Summary',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      _buildSummaryRow(
                        '🏟 Turf',
                        widget.turfName,
                        isSmallScreen,
                      ),
                      _buildSummaryRow(
                        '📍 Location',
                        widget.location,
                        isSmallScreen,
                      ),
                      _buildSummaryRow(
                        '⚽ Sport',
                        selectedSport ?? 'Not selected',
                        isSmallScreen,
                      ),
                      _buildSummaryRow(
                        '📅 Date',
                        '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
                        isSmallScreen,
                      ),
                      _buildSummaryRow(
                        '⏰ Time',
                        '${formatHour(selectedStartHour, isStartAM)} - ${formatHour(selectedEndHour, isEndAM)}',
                        isSmallScreen,
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 20),
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '💰 Total Amount',
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
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // Enhanced Book Now Button
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
                              height: isSmallScreen ? 50 : 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
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
                                            Colors.white.withOpacity(0.2),
                                            Colors.white.withOpacity(0.1),
                                          ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color:
                                      selectedSport != null
                                          ? Colors.green.withOpacity(0.5)
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
                                                  Icons.payment,
                                                  color: Colors.white,
                                                  size: isSmallScreen ? 20 : 24,
                                                ),
                                                SizedBox(
                                                  width: isSmallScreen ? 8 : 12,
                                                ),
                                                Text(
                                                  'Book Now & Pay',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize:
                                                        isSmallScreen ? 16 : 18,
                                                    fontWeight: FontWeight.bold,
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

                      SizedBox(height: isSmallScreen ? 12 : 16),
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
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmallScreen ? 100 : 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
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

  // Enhanced Success Popup with Booking Details
  // Enhanced Success Popup with better responsiveness and animations
  void _showBookingSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenWidth < 400;
            final isExtraSmallScreen = screenWidth < 350;
            final isTablet = screenWidth >= 600;

            // Responsive dimensions
            final dialogWidth =
                isTablet
                    ? screenWidth * 0.6
                    : isSmallScreen
                    ? screenWidth * 0.92
                    : screenWidth * 0.88;

            final maxDialogHeight = screenHeight * 0.9;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isExtraSmallScreen ? 8 : 16,
                vertical: 20,
              ),
              child: Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxHeight: maxDialogHeight,
                  maxWidth: isTablet ? 500 : double.infinity,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
                        borderRadius: BorderRadius.circular(
                          isSmallScreen ? 16 : 20,
                        ),
                        border: Border.all(
                          width: 1.5,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(
                          isExtraSmallScreen
                              ? 16
                              : isSmallScreen
                              ? 20
                              : 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Success Icon with enhanced animation
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1200),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 800),
                                    padding: EdgeInsets.all(
                                      isExtraSmallScreen
                                          ? 12
                                          : isSmallScreen
                                          ? 16
                                          : 20,
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
                                      Icons.check_circle,
                                      color: Colors.green.shade300,
                                      size:
                                          isExtraSmallScreen
                                              ? 40
                                              : isSmallScreen
                                              ? 48
                                              : isTablet
                                              ? 64
                                              : 56,
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(
                              height:
                                  isExtraSmallScreen
                                      ? 16
                                      : isSmallScreen
                                      ? 20
                                      : 24,
                            ),

                            // Success Title with staggered animation
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
                                        fontSize:
                                            isExtraSmallScreen
                                                ? 18
                                                : isSmallScreen
                                                ? 22
                                                : isTablet
                                                ? 28
                                                : 26,
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

                            SizedBox(
                              height:
                                  isExtraSmallScreen
                                      ? 8
                                      : isSmallScreen
                                      ? 12
                                      : 16,
                            ),

                            // Booking Details Container with slide-up animation
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
                                        isExtraSmallScreen
                                            ? 12
                                            : isSmallScreen
                                            ? 16
                                            : 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 12 : 16,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.25),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Booking ID with improved responsive design
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  isExtraSmallScreen
                                                      ? 8
                                                      : isSmallScreen
                                                      ? 12
                                                      : 16,
                                              vertical:
                                                  isExtraSmallScreen
                                                      ? 6
                                                      : isSmallScreen
                                                      ? 8
                                                      : 10,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.blue.withOpacity(0.3),
                                                  Colors.blue.withOpacity(0.2),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                                  Icons.confirmation_number,
                                                  color: Colors.blue.shade300,
                                                  size:
                                                      isExtraSmallScreen
                                                          ? 16
                                                          : isSmallScreen
                                                          ? 18
                                                          : 20,
                                                ),
                                                SizedBox(
                                                  width:
                                                      isExtraSmallScreen
                                                          ? 6
                                                          : 8,
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    'ID: ${bookingId ?? 'N/A'}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize:
                                                          isExtraSmallScreen
                                                              ? 12
                                                              : isSmallScreen
                                                              ? 14
                                                              : 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(
                                            height:
                                                isExtraSmallScreen
                                                    ? 12
                                                    : isSmallScreen
                                                    ? 16
                                                    : 20,
                                          ),

                                          // Booking Details with better spacing
                                          ..._buildAnimatedDetailRows(
                                            isExtraSmallScreen,
                                            isSmallScreen,
                                          ),

                                          SizedBox(
                                            height:
                                                isExtraSmallScreen
                                                    ? 8
                                                    : isSmallScreen
                                                    ? 12
                                                    : 16,
                                          ),

                                          // Amount Container with enhanced styling
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(
                                              isExtraSmallScreen
                                                  ? 10
                                                  : isSmallScreen
                                                  ? 12
                                                  : 16,
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
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.green
                                                      .withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    '💰 Amount Paid',
                                                    style: GoogleFonts.poppins(
                                                      fontSize:
                                                          isExtraSmallScreen
                                                              ? 14
                                                              : isSmallScreen
                                                              ? 16
                                                              : 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${bookingAmount.toStringAsFixed(0)}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize:
                                                        isExtraSmallScreen
                                                            ? 16
                                                            : isSmallScreen
                                                            ? 18
                                                            : 22,
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

                            SizedBox(
                              height:
                                  isExtraSmallScreen
                                      ? 16
                                      : isSmallScreen
                                      ? 20
                                      : 24,
                            ),

                            // Action Buttons with improved animations
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
                                          height:
                                              isExtraSmallScreen
                                                  ? 44
                                                  : isSmallScreen
                                                  ? 48
                                                  : 54,
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
                                          icon: Icons.download,
                                          text: 'Download Voucher',
                                          fontSize:
                                              isExtraSmallScreen
                                                  ? 14
                                                  : isSmallScreen
                                                  ? 16
                                                  : 18,
                                          iconSize:
                                              isExtraSmallScreen
                                                  ? 18
                                                  : isSmallScreen
                                                  ? 20
                                                  : 22,
                                          onTap: () async {
                                            Navigator.of(context).pop();
                                            await _generateAndShareBookingPDF();
                                          },
                                          isSmallScreen: isExtraSmallScreen,
                                        ),

                                        SizedBox(
                                          height:
                                              isExtraSmallScreen
                                                  ? 10
                                                  : isSmallScreen
                                                  ? 12
                                                  : 16,
                                        ),

                                        // Back to Home Button
                                        _buildAnimatedButton(
                                          width: double.infinity,
                                          height:
                                              isExtraSmallScreen
                                                  ? 44
                                                  : isSmallScreen
                                                  ? 48
                                                  : 54,
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
                                          icon: Icons.home,
                                          text: 'Back to Home',
                                          fontSize:
                                              isExtraSmallScreen
                                                  ? 14
                                                  : isSmallScreen
                                                  ? 16
                                                  : 18,
                                          iconSize:
                                              isExtraSmallScreen
                                                  ? 18
                                                  : isSmallScreen
                                                  ? 20
                                                  : 22,
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                          },
                                          isSmallScreen: isExtraSmallScreen,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(
                              height:
                                  isExtraSmallScreen
                                      ? 12
                                      : isSmallScreen
                                      ? 16
                                      : 20,
                            ),

                            // Footer Message with fade-in animation
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1400),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeIn,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      isExtraSmallScreen
                                          ? 10
                                          : isSmallScreen
                                          ? 12
                                          : 16,
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
                                            fontSize:
                                                isExtraSmallScreen
                                                    ? 12
                                                    : isSmallScreen
                                                    ? 14
                                                    : 16,
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
                                            fontSize:
                                                isExtraSmallScreen
                                                    ? 11
                                                    : isSmallScreen
                                                    ? 12
                                                    : 14,
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
  List<Widget> _buildAnimatedDetailRows(
    bool isExtraSmallScreen,
    bool isSmallScreen,
  ) {
    final List<Map<String, String>> details = [
      {'label': '🏟 Turf', 'value': widget.turfName},
      {'label': '📍 Location', 'value': widget.location},
      {'label': '⚽ Sport', 'value': selectedSport ?? 'N/A'},
      {
        'label': '📅 Date',
        'value':
            '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
      },
      {
        'label': '⏰ Time Slot',
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
                padding: EdgeInsets.symmetric(
                  vertical:
                      isExtraSmallScreen
                          ? 4
                          : isSmallScreen
                          ? 6
                          : 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width:
                          isExtraSmallScreen
                              ? 80
                              : isSmallScreen
                              ? 90
                              : 110,
                      child: Text(
                        detail['label']!,
                        style: GoogleFonts.poppins(
                          fontSize:
                              isExtraSmallScreen
                                  ? 11
                                  : isSmallScreen
                                  ? 13
                                  : 15,
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
                          fontSize:
                              isExtraSmallScreen
                                  ? 11
                                  : isSmallScreen
                                  ? 13
                                  : 15,
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
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
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
                onTapDown: (_) {
                  // Add tap animation if needed
                },
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: iconSize),
                      SizedBox(width: isSmallScreen ? 6 : 12),
                      Flexible(
                        child: Text(
                          text,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(),
                _buildSportSearchCard(filteredSports),
                _buildDateTimeCard(),
                _buildBookingCard(),
                const SizedBox(height: 32),
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
  }
}
