import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fura24.kz/shared/widgets/single_appbar.dart';

class RidesTab extends StatefulWidget {
  const RidesTab({super.key});

  @override
  State<RidesTab> createState() => _RidesTabState();
}

class _RidesTabState extends State<RidesTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SingleAppbar(title: 'Избранное'),
    );
  }
}
