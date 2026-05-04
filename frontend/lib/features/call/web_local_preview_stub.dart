import 'package:flutter/widgets.dart';

class WebLocalPreview extends StatelessWidget {
  const WebLocalPreview({super.key, required this.fallback});

  final Widget fallback;

  @override
  Widget build(BuildContext context) => fallback;
}
