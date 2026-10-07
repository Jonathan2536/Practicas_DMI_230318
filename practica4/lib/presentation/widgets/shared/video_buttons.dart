import 'package:flutter/material.dart';
import 'package:practica4/config/helpers/human_formats.dart';
import 'package:practica4/domain/entities/video_post.dart';


class VideoButtons extends StatelessWidget {

  final VideoPost video;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final bool isLikeUpdatePending;
  final VoidCallback onToggleLike;

  const VideoButtons({
    super.key, 
    required this.video,
    required this.isMuted,
    required this.onToggleMute,
    required this.isLikeUpdatePending,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CustomIconButton(
          value: video.likes,
          iconColor: Colors.red,
          iconData: video.isLiked ? Icons.favorite : Icons.favorite_border,
          onPressed: isLikeUpdatePending ? null : onToggleLike,
        ),
        const SizedBox( height: 20 ),
        _CustomIconButton( value: video.views, iconData: Icons.remove_red_eye_outlined ),

        const SizedBox( height: 20 ),
        
        // Mute button
        IconButton(
          onPressed: onToggleMute,
          icon: Icon(
            isMuted ? Icons.volume_off : Icons.volume_up, 
            color: Colors.white, 
            size: 35
          )
        )
      ],
    );
  }
}


class _CustomIconButton extends StatelessWidget {

  final int value;
  final IconData iconData;
  final Color? color;
  final VoidCallback? onPressed;

  const _CustomIconButton({
    required this.value, 
    required this.iconData, 
    Color? iconColor,
    this.onPressed = _defaultOnPressed,
  }) : color = iconColor ?? Colors.white;

  static void _defaultOnPressed() {}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon( iconData, color: color, size: 30, )),

        if ( value > 0 )
        Text( HumanFormats.humanReadbleNumber(value.toDouble()) ),
      ],
    );
  }
}
