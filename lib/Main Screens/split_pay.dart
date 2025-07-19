import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../Providers/split_pay_provider.dart';

class SplitPaymentScreen extends ConsumerWidget {
  const SplitPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF2C003E),
      body: SafeArea(
        child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Split payment',
                      style: GoogleFonts.robotoSlab(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Share code box
              _buildStartPlayingCard(ref),

              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "See My team",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Team list
              Expanded(
                child: ListView.builder(
                  itemCount: team.length,
                  itemBuilder: (context, index) {
                    final member = team[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xcd330a47),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: member.avatarUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(member.avatarUrl)
                                  : null,
                              child: member.avatarUrl.isEmpty
                                  ? const Icon(
                                      Icons.groups,
                                      color: Colors.black,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 28),
                            Text(
                              member.name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: member.status == PaymentStatus.paid
                                    ? Colors.green
                                    : const Color(0xffD72664),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                member.status == PaymentStatus.paid
                                    ? 'paid'
                                    : 'Request',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Done Button
              Center(
                child: GestureDetector(
                  onTap: () {
                    Razorpay razorpay = Razorpay();
                    var options = {
                      'key': 'rzp_test_0rwYxZvUXDUeW7',
                      'amount': 100,
                      'name': 'Acme Corp.',
                      'description': 'Fine T-Shirt',
                      'retry': {'enabled': true, 'max_count': 1},
                      'send_sms_hash': true,
                      'prefill': {
                        'contact': '8888888888',
                        'email': 'test@razorpay.com',
                      },
                      'external': {
                        'wallets': ['paytm'],
                      },
                    };
                    razorpay.on(
                      Razorpay.EVENT_PAYMENT_ERROR,
                      handlePaymentErrorResponse,
                    );
                    razorpay.on(
                      Razorpay.EVENT_PAYMENT_SUCCESS,
                      handlePaymentSuccessResponse,
                    );
                    razorpay.on(
                      Razorpay.EVENT_EXTERNAL_WALLET,
                      handleExternalWalletSelected,
                    );
                    razorpay.open(options);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE60073),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      "Done",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ Helper for generating team code
String generateRandomTeamCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return String.fromCharCodes(
    Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
  );
}

/// ✅ Start Playing Card with Code
Widget _buildStartPlayingCard(WidgetRef ref) {
  final isTeamCreated = ref.watch(isTeamCreatedProvider);
  final teamCode = ref.watch(teamCodeProvider);

  return Card(
    elevation: 6,
    color: const Color(0xcf623173),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 150,
              child: Card(
                color: const Color(0x5ddcdcdc),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0x98dcdcdc), width: 1.5),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Center(
                    child: Text(
                      'Share Code!',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Color(0xffd2cdcd),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTeamCreated ? 'Team Code: $teamCode' : 'Generate Team Code',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              ElevatedButton(
                onPressed: isTeamCreated
                    ? null
                    : () {
                        final generatedCode = generateRandomTeamCode();
                        ref.read(teamCodeProvider.notifier).state =
                            generatedCode;
                        ref.read(isTeamCreatedProvider.notifier).state = true;
                      },
                style: ElevatedButton.styleFrom(
                  elevation: 10,
                  backgroundColor: const Color(0xffD72664),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      isTeamCreated ? teamCode ?? '' : "Generate",
                      style: GoogleFonts.robotoSlab(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.share, color: Colors.white, size: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Only Selected Can Join By Creator.',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
              ),
              SizedBox(height: 4),
              Divider(
                color: Colors.white,
                thickness: 1,
                indent: 6,
                endIndent: 6,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void handlePaymentErrorResponse(PaymentFailureResponse response) {
  /*
    * PaymentFailureResponse contains three values:
    * 1. Error Code
    * 2. Error Description
    * 3. Metadata
    * */
  showAlertDialog(
    context as BuildContext,
    "Payment Failed",
    "Code: ${response.code}\nDescription: ${response.message}\nMetadata:${response.error.toString()}",
  );
}

void handlePaymentSuccessResponse(PaymentSuccessResponse response) {
  /*
    * Payment Success Response contains three values:
    * 1. Order ID
    * 2. Payment ID
    * 3. Signature
    * */
  showAlertDialog(
    context as BuildContext,
    "Payment Successful",
    "Payment ID: ${response.paymentId}",
  );
}

void handleExternalWalletSelected(ExternalWalletResponse response) {
  showAlertDialog(
    context as BuildContext,
    "External Wallet Selected",
    "${response.walletName}",
  );
}

void showAlertDialog(BuildContext context, String title, String message) {
  // set up the buttons
  // set up the AlertDialog
  AlertDialog alert = AlertDialog(title: Text(title), content: Text(message));
  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
