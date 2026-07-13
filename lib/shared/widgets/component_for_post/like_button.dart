import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../config_App/image.dart';
import '../iconsvg.dart';

class LikeButtons extends StatefulWidget {
  final bool isLiked;
  final int likes;
  final String ?link;
  final Future<bool?> Function(bool)? like;

  const LikeButtons({super.key,  this.isLiked = false,  this.likes=0, required this.like,  this.link });

  @override
  State<LikeButtons> createState() => _LikeButtonsState();
}

class _LikeButtonsState extends State<LikeButtons> {
  @override
  Widget build(BuildContext context) {
    return  LikeButton(
      onTap: widget.like,
      isLiked: widget.isLiked,
      likeCount: widget.likes,
      countBuilder: (int? count, bool isLiked, String text) {
        final Color color = isLiked ? Colors.deepPurpleAccent : Colors.grey;

        if (count == null || count == 0) {
          return Text(
            "0",
            style: TextStyle(color: color,fontWeight: FontWeight.bold),
          );
        }

        return Text(
          text,
          style: TextStyle(color: color,fontWeight: FontWeight.bold),
        );
      },
      likeBuilder: (bool isLiked) {
        return Iconsvg(
          color: isLiked ? const Color(0xff38B65F) : Colors.black,
          link: widget.link ?? Consticon.like,
          heigth: 2.2.h,
          width: 2.w,
        );
      },
      likeCountPadding: EdgeInsets.only(left: 2.w),
    );
  }
}
