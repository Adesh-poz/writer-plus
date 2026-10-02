import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class WriterPlusLogoText extends StatelessWidget {
  const WriterPlusLogoText({
    super.key,
    this.iconColor,
    this.textColor,
    this.disableOnPress,
  });

  final Color? iconColor;
  final Color? textColor;
  final bool? disableOnPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (disableOnPress != true) Navigator.pushNamed(context, '/info');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.feather,
            size: 22,
            color: iconColor ?? Colors.white,
          ),
          const SizedBox(width: 10),
          Text(
            'Writer Plus',
            style: GoogleFonts.charm(
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: textColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
