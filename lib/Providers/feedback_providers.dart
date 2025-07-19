import 'package:flutter_riverpod/flutter_riverpod.dart';

final feedbackProvider = StateNotifierProvider<FeedbackNotifier, FeedbackState>(
      (ref) => FeedbackNotifier(),
);

class FeedbackState {
  final int selectedEmoji;
  final String? selectedOption;

  FeedbackState({this.selectedEmoji = -1, this.selectedOption});

  FeedbackState copyWith({int? selectedEmoji, String? selectedOption}) {
    return FeedbackState(
      selectedEmoji: selectedEmoji ?? this.selectedEmoji,
      selectedOption: selectedOption ?? this.selectedOption,
    );
  }
}

class FeedbackNotifier extends StateNotifier<FeedbackState> {
  FeedbackNotifier() : super(FeedbackState());

  void selectEmoji(int index) {
    state = state.copyWith(selectedEmoji: index);
  }

  void selectOption(String option) {
    state = state.copyWith(selectedOption: option);
  }

  bool get isComplete =>
      state.selectedEmoji != -1 && state.selectedOption != null;
}