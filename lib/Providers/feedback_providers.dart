import 'package:flutter_riverpod/flutter_riverpod.dart';

// Feedback State Model
class FeedbackState {
  final int? selectedEmoji;
  final String? selectedOption;

  FeedbackState({this.selectedEmoji, this.selectedOption});

  FeedbackState copyWith({int? selectedEmoji, String? selectedOption}) {
    return FeedbackState(
      selectedEmoji: selectedEmoji ?? this.selectedEmoji,
      selectedOption: selectedOption ?? this.selectedOption,
    );
  }
}

// Feedback Notifier
class FeedbackNotifier extends StateNotifier<FeedbackState> {
  FeedbackNotifier() : super(FeedbackState());

  void selectEmoji(int index) {
    state = state.copyWith(selectedEmoji: index);
  }

  void selectOption(String option) {
    state = state.copyWith(selectedOption: option);
  }

  void reset() {
    state = FeedbackState();
  }

  bool get isComplete {
    return state.selectedEmoji != null &&
        state.selectedOption != null &&
        state.selectedOption != "Select topic";
  }
}

// Provider
final feedbackProvider = StateNotifierProvider<FeedbackNotifier, FeedbackState>(
  (ref) => FeedbackNotifier(),
);
