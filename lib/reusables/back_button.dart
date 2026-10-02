import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WriterBackButton extends StatelessWidget {
  const WriterBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Go Back',
      onPressed: () => Navigator.pop(context),
      icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 18),
    );
  }
}
