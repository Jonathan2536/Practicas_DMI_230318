import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:tistos/config/helpers/human_formats.dart';
import 'package:tistos/domain/entities/video_post.dart';


class VideoButtons extends StatelessWidget {

  final VideoPost video;
  final bool isMuted;
  final VoidCallback onToggleMute;

  const VideoButtons({
    super.key, 
    required this.video,
    required this.isMuted,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CustomIconButton( value: video.likes, iconColor: Colors.red, iconData: Icons.favorite, ),
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

  const _CustomIconButton({
    required this.value, 
    required this.iconData, 
    iconColor
  }): color = iconColor ?? Colors.white;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: () {}, 
          icon: Icon( iconData, color: color, size: 30, )),

        if ( value > 0 )
        Text( HumanFormats.humanReadbleNumber(value.toDouble()) ),
      ],
    );
  }
}
