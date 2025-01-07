import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/verse.dart';
import '../extensions/arabic_number.dart';

class VerseDisplay extends StatelessWidget {
  final Verse verse;
  final double fontSize;
  final Color? textColor;

  const VerseDisplay({
    super.key,
    required this.verse,
    required this.fontSize,
    this.textColor,
  });

  String _cleanText(String text) {
    return text.replaceAll('۟', '');
  }

  @override
  Widget build(BuildContext context) {
    final verseNumber = int.parse(verse.verseKey.split(':')[1]);
    return Html(
      data: '''
        <style>
          span[class=end] { 
            color: ${Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: (255 * 0.5).round().toDouble())} !important; 
            font-size: 0.8em !important;
            line-height: 1.5em !important;
            vertical-align: middle !important;
            margin-inline-start: 8px !important;
          }
        </style>
        ${_cleanText(verse.textUthmani)} <span class="end">${verseNumber.toArabicDigits()}</span>
      ''',
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(fontSize),
          fontFamily: 'Uthmani',
          color: textColor,
          textAlign: TextAlign.justify,
          direction: TextDirection.rtl,
          lineHeight: LineHeight.number(1.8),
        ),
      },
    );
  }
}
