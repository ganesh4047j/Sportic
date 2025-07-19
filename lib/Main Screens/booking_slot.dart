import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';
import 'package:sports/Main%20Screens/split_pay.dart';

class TimingPage extends StatefulWidget {
  const TimingPage({super.key});

  @override
  State<TimingPage> createState() => _TimingPageState();
}

class _TimingPageState extends State<TimingPage> {
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

  List<String> sports = [
    'Football',
    'Cricket',
    'Basketball',
    'Tennis',
    'Hockey',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredSports =
        searchText.isEmpty
            ? sports
            : sports
                .where(
                  (s) => s.toLowerCase().contains(searchText.toLowerCase()),
                )
                .toList();

    return Scaffold(
      backgroundColor: const Color(0xff563062),
      appBar: AppBar(
        backgroundColor: const Color(0xff563062),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 15),
              Text(
                "Book Your Slots",
                style: GoogleFonts.robotoSlab(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              "Find by Sport and Open Times",
              style: GoogleFonts.cutive(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 🔍 Sport Search
            _buildSportSearchCard(filteredSports),

            const SizedBox(height: 20),

            // 📅 Date & Time
            _buildDateTimeCard(),

            const SizedBox(height: 20),

            // ✅ Selection Summary
            _buildSelectionSummaryCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildSportSearchCard(List<String> filteredSports) {
    return Card(
      color: const Color(0xff371d3e),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xff8d918d)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
               Text(
                  "Search Sports",
                  style: GoogleFonts.poppins(
                    color: Color(0xddb7b5b5),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed:
                      () => setState(() {
                        showSearchField = !showSearchField;
                        if (!showSearchField) searchText = '';
                      }),
                ),
              ],
            ),
            if (showSearchField)
              TextField(
                onChanged: (value) => setState(() => searchText = value),
                keyboardType: TextInputType.text,
                autofocus: true,
                style:GoogleFonts.nunito(color: Colors.white),
                decoration:  InputDecoration(
                  hintText: "Enter sport name...",
                  hintStyle: GoogleFonts.nunito(color: Colors.grey),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(filteredSports.length, (index) {
                  final sport = filteredSports[index];
                  final isSelected = selectedSport == sport;
                  return GestureDetector(
                    onTap:
                        () => setState(() {
                          selectedSport = isSelected ? null : sport;
                          showSearchField = false;
                          searchText = '';
                        }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        sport,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xff8d918d)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  "Check venue availability",
                  style: GoogleFonts.robotoSlab(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Date",
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}",
                  style:  GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed:
                      () => setState(() => _selectedDate = DateTime.now()),
                  child: Text(
                    "TODAY",
                    style:GoogleFonts.nunito(color: Colors.red),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 250,
              child: ScrollDatePicker(
                selectedDate: _selectedDate,
                minimumDate: DateTime(DateTime.now().year),
                maximumDate: DateTime(DateTime.now().year + 10),
                locale: const Locale('en'),
                onDateTimeChanged:
                    (value) => setState(() => _selectedDate = value),
              ),
            ),

            const Divider(height: 30, color: Colors.black26),

            _buildHourPicker("Start Time", selectedStartHour, isStartAM, true),
            const SizedBox(height: 16),
            _buildHourPicker("End Time", selectedEndHour, isEndAM, false),
          ],
        ),
      ),
    );
  }

  Widget _buildHourPicker(
    String label,
    int selectedHour,
    bool isAm,
    bool isStart,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 150,
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 60,
                  perspective: 0.005,
                  diameterRatio: 2,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      if (isStart) {
                        selectedStartHour = index + 1;
                      } else {
                        selectedEndHour = index + 1;
                      }
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      final hour = index + 1;
                      final isSelected =
                          isStart
                              ? selectedStartHour == hour
                              : selectedEndHour == hour;
                      return Center(
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.deepPurple
                                    : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$hour:00',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ToggleButtons(
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              color: Colors.black,
              fillColor: Colors.deepPurple,
              isSelected: isStart ? [isAm, !isAm] : [isAm, !isAm],
              onPressed: (index) {
                setState(() {
                  if (isStart) {
                    isStartAM = index == 0;
                  } else {
                    isEndAM = index == 0;
                  }
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('AM'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('PM'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionSummaryCard() {
    String formatHour(int hour, bool isAm) {
      final formatted = hour.toString().padLeft(2, '0');
      final suffix = isAm ? 'AM' : 'PM';
      return '$formatted:00 $suffix';
    }

    return Card(
      color: const Color(0xffc19ecb),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xff8d918d)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Selection",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedSport ?? "No sport",
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                Text(
                  "${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}",
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                Text(
                  "${formatHour(selectedStartHour, isStartAM)} - ${formatHour(selectedEndHour, isEndAM)}",
                  style:GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedSport = null;
                _selectedDate = DateTime.now();
                selectedStartHour =
                    TimeOfDay.now().hour % 12 == 0
                        ? 12
                        : TimeOfDay.now().hour % 12;
                isStartAM = TimeOfDay.now().hour < 12;
                selectedEndHour =
                    ((TimeOfDay.now().hour + 1) % 12 == 0)
                        ? 12
                        : (TimeOfDay.now().hour + 1) % 12;
                isEndAM = (TimeOfDay.now().hour + 1) < 12;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff7f7e7d),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:  Text(
              "Reset",
              style: GoogleFonts.nunito(color: Colors.black, fontSize: 15.0),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SplitPaymentScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff37a057),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Confirm",
              style: GoogleFonts.nunito(color: Colors.white, fontSize: 15.0),
            ),
          ),
        ],
      ),
    );
  }
}
