import 'package:flutter_riverpod/flutter_riverpod.dart';

final turfProvider = StateProvider<List<TurfModel>>((ref) => [
  TurfModel(
      name: "turf name 33", imageUrl: "https://i.ibb.co/hDqLgL3/turf1.jpg"),
  TurfModel(
      name: "turf  name 2", imageUrl: "https://i.ibb.co/YTd7NW2/turf2.jpg"),
  TurfModel(
      name: "turf name 4", imageUrl: "https://i.ibb.co/hDqLgL3/turf1.jpg"),
  TurfModel(
      name: "turf name 23", imageUrl: "https://i.ibb.co/hDqLgL3/turf1.jpg"),
  TurfModel(
      name: "turf name 11", imageUrl: "https://i.ibb.co/hDqLgL3/turf1.jpg"),
  TurfModel(
      name: "turf name 91", imageUrl: "https://i.ibb.co/hDqLgL3/turf1.jpg"),
]);

class TurfModel {
  final String name;
  final String imageUrl;

  TurfModel({required this.name, required this.imageUrl});
}