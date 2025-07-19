// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:uuid/uuid.dart';
// import 'package:video_player/video_player.dart';
// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
//
// // ------------------ Models ------------------
// class Comment {
//   final String id;
//   final String username;
//   final String text;
//   int likes;
//   int dislikes;
//   bool isLiked;
//   bool isDisliked;
//
//   Comment({
//     required this.id,
//     required this.username,
//     required this.text,
//     this.likes = 0,
//     this.dislikes = 0,
//     this.isLiked = false,
//     this.isDisliked = false,
//   });
// }
//
// // ------------------ State Notifier ------------------
// class CommentsNotifier extends StateNotifier<List<Comment>> {
//   CommentsNotifier() : super([]) {
//     _initDummyData();
//   }
//
//   void _initDummyData() {
//     for (int i = 0; i < 10; i++) {
//       state = [
//         ...state,
//         Comment(
//           id: const Uuid().v4(),
//           username: 'godwinjeraldwilliam',
//           text: 'Smooth and Even Surface',
//           likes: 125,
//         )
//       ];
//     }
//   }
//
//   void toggleLike(String id) {
//     state = [
//       for (final c in state)
//         if (c.id == id)
//           Comment(
//             id: c.id,
//             username: c.username,
//             text: c.text,
//             likes: c.isLiked ? c.likes - 1 : c.likes + 1,
//             dislikes: c.isDisliked ? c.dislikes - 1 : c.dislikes,
//             isLiked: !c.isLiked,
//             isDisliked: false,
//           )
//         else
//           c
//     ];
//   }
//
//   void toggleDislike(String id) {
//     state = [
//       for (final c in state)
//         if (c.id == id)
//           Comment(
//             id: c.id,
//             username: c.username,
//             text: c.text,
//             likes: c.isLiked ? c.likes - 1 : c.likes,
//             dislikes: c.isDisliked ? c.dislikes - 1 : c.dislikes + 1,
//             isLiked: false,
//             isDisliked: !c.isDisliked,
//           )
//         else
//           c
//     ];
//   }
//
//   void addComment(Comment comment) {
//     state = [...state, comment];
//   }
// }
//
// final commentsProvider =
// StateNotifierProvider<CommentsNotifier, List<Comment>>((ref) {
//   return CommentsNotifier();
// });
//
// final commentInputProvider = StateProvider<String>((ref) => '');
//
// // ------------------ Main UI Page ------------------
// class LiveCommentPage extends ConsumerStatefulWidget {
//   const LiveCommentPage({super.key});
//
//   @override
//   ConsumerState<LiveCommentPage> createState() => _LiveCommentPageState();
// }
//
// class _LiveCommentPageState extends ConsumerState<LiveCommentPage> {
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _textController = TextEditingController();
//   late VideoPlayerController _videoController;
//   bool _showEmojiPicker = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _videoController = VideoPlayerController.asset(
//       'assets/sample_video.mp4',
//     )
//       ..initialize().then((_) => setState(() {}))
//       ..setLooping(true)
//       ..play();
//   }
//
//   @override
//   void dispose() {
//     _videoController.dispose();
//     _scrollController.dispose();
//     _textController.dispose();
//     super.dispose();
//   }
//
//   void _submitComment() {
//     final text = _textController.text.trim();
//     if (text.isNotEmpty) {
//       ref.read(commentsProvider.notifier).addComment(
//         Comment(
//           id: const Uuid().v4(),
//           username: 'godwinjeraldwilliam',
//           text: text,
//         ),
//       );
//       _textController.clear();
//       ref.read(commentInputProvider.notifier).state = '';
//       setState(() => _showEmojiPicker = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     ref.listen<List<Comment>>(commentsProvider, (previous, next) {
//       if (next.length > (previous?.length ?? 0)) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (_scrollController.hasClients) {
//             _scrollController.animateTo(
//               _scrollController.position.maxScrollExtent + 100,
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeOut,
//             );
//           }
//         });
//       }
//     });
//
//     final comments = ref.watch(commentsProvider);
//
//     return GestureDetector(
//       onTap: () {
//         FocusScope.of(context).unfocus();
//         setState(() => _showEmojiPicker = false);
//       },
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         backgroundColor: Colors.black,
//         body: Stack(
//           children: [
//             // Fullscreen Video
//             if (_videoController.value.isInitialized)
//               Positioned.fill(
//                 child: FittedBox(
//                   fit: BoxFit.cover,
//                   child: SizedBox(
//                     width: _videoController.value.size.width,
//                     height: _videoController.value.size.height,
//                     child: VideoPlayer(_videoController),
//                   ),
//                 ),
//               ),
//
//             // Overlayed UI
//             Column(
//               children: [
//                 const SizedBox(height: 40),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.arrow_back_ios,
//                             color: Colors.white),
//                         onPressed: () => Navigator.of(context).pop(),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close, color: Colors.white),
//                         onPressed: () => Navigator.of(context).pop(),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Live comments',
//                           style: TextStyle(
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white)),
//                       SizedBox(height: 6),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text('Top Comments',
//                               style: TextStyle(color: Colors.white70)),
//                           Row(
//                             children: [
//                               Icon(Icons.person,
//                                   color: Colors.white70, size: 18),
//                               SizedBox(width: 4),
//                               Text('4.5k',
//                                   style: TextStyle(color: Colors.white70))
//                             ],
//                           ),
//                         ],
//                       )
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Expanded(
//                   child: ListView.builder(
//                     controller: _scrollController,
//                     itemCount: comments.length,
//                     itemBuilder: (context, index) {
//                       final c = comments[index];
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(
//                             vertical: 8.0, horizontal: 16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 const CircleAvatar(
//                                     radius: 12,
//                                     backgroundColor: Colors.white,
//                                     child: Icon(Icons.person, size: 14)),
//                                 const SizedBox(width: 8),
//                                 Text('@${c.username}',
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.white)),
//                               ],
//                             ),
//                             const SizedBox(height: 4),
//                             Padding(
//                               padding: const EdgeInsets.only(left: 32.0),
//                               child: Text(c.text,
//                                   style:
//                                   const TextStyle(color: Colors.white70)),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.only(left: 32.0),
//                               child: Row(
//                                 children: [
//                                   IconButton(
//                                     icon: Icon(Icons.thumb_up,
//                                         size: 16,
//                                         color: c.isLiked
//                                             ? Colors.pink
//                                             : Colors.white70),
//                                     onPressed: () => ref
//                                         .read(commentsProvider.notifier)
//                                         .toggleLike(c.id),
//                                   ),
//                                   Text('${c.likes}',
//                                       style: const TextStyle(
//                                           color: Colors.white70)),
//                                   IconButton(
//                                     icon: Icon(Icons.thumb_down,
//                                         size: 16,
//                                         color: c.isDisliked
//                                             ? Colors.pink
//                                             : Colors.white70),
//                                     onPressed: () => ref
//                                         .read(commentsProvider.notifier)
//                                         .toggleDislike(c.id),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   const Text("reply",
//                                       style: TextStyle(color: Colors.white70))
//                                 ],
//                               ),
//                             )
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 // Input Field
//                 Padding(
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: const Color(0xff6e0795),
//                       borderRadius: BorderRadius.circular(24),
//                     ),
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             cursorColor: Colors.white,
//                             cursorHeight: 25,
//                             controller: _textController,
//                             style: const TextStyle(color: Colors.white),
//                             decoration: const InputDecoration(
//                               hintText: "Your Comments...",
//                               hintStyle: TextStyle(color: Colors.white54),
//                               border: InputBorder.none,
//                             ),
//                             onChanged: (val) => ref
//                                 .read(commentInputProvider.notifier)
//                                 .state = val,
//                             onSubmitted: (_) => _submitComment(),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.emoji_emotions,
//                               color: Colors.white70),
//                           onPressed: () {
//                             FocusScope.of(context).unfocus();
//                             setState(
//                                     () => _showEmojiPicker = !_showEmojiPicker);
//                           },
//                         )
//                       ],
//                     ),
//                   ),
//                 ),
//                 // Emoji Picker
//                 if (_showEmojiPicker)
//                   SizedBox(
//                     height: 250,
//                     child: EmojiPicker(
//                       onEmojiSelected: (category, emoji) {
//                         final newText = _textController.text + emoji.emoji;
//                         _textController.text = newText;
//                         _textController.selection = TextSelection.fromPosition(
//                           TextPosition(offset: newText.length),
//                         );
//                         ref.read(commentInputProvider.notifier).state = newText;
//                       },
//                       config: const Config(
//                         emojiViewConfig: EmojiViewConfig(
//                           emojiSizeMax: 32,
//                           columns: 7,
//                         ),
//                         categoryViewConfig: CategoryViewConfig(
//                           indicatorColor: Colors.purple,
//                           iconColor: Colors.grey,
//                           iconColorSelected: Colors.purple,
//                           backspaceColor: Colors.purple,
//                         ),
//                         skinToneConfig: SkinToneConfig(),
//                         bottomActionBarConfig: BottomActionBarConfig(),
//                         searchViewConfig: SearchViewConfig(),
//                       ),
//                     ),
//                   ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }










import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

final lottieControllerProvider =
Provider.autoDispose<AnimationController?>((ref) => null);

class CenterLottieScreen extends ConsumerStatefulWidget {
  const CenterLottieScreen({super.key});

  @override
  ConsumerState<CenterLottieScreen> createState() => _CenterLottieScreenState();
}

class _CenterLottieScreenState extends ConsumerState<CenterLottieScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                child: DefaultTextStyle(
                  style: GoogleFonts.nunito(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Match your theme
                  ),
                  child: AnimatedTextKit(
                    repeatForever: true,
                    animatedTexts: [
                      TypewriterAnimatedText('Coming Soon...'),
                    ],
                    onTap: () {},
                  ),
                ),
              ),
              Lottie.asset(
                'assets/coming_soon.json',
                repeat: true,
                controller: _controller,
                onLoaded: (composition) {
                  _controller
                    ..duration = composition.duration
                    ..repeat();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}