import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Bismillah extends StatelessWidget {
  const Bismillah({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    print('Building Bismillah widget');
    print('isDark: $isDark');
    print(
        'Asset path: ${isDark ? 'assets/bismillah-white.svg' : 'assets/bismillah-black.svg'}');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: SvgPicture.asset(
          isDark ? 'assets/bismillah-white.svg' : 'assets/bismillah-black.svg',
          width: 220,
          height: 45,
          colorFilter: ColorFilter.mode(
            Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
