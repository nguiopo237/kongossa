import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



class CustomText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign align;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool selectable;
  final TextType type;

  const CustomText(
      this.text, {
        super.key,
        this.style,
        this.align = TextAlign.start,
        this.maxLines,
        this.overflow,
        this.selectable = false,
        this.type = TextType.bodyMedium,
      });

  @override
  Widget build(BuildContext context) {
    final textStyle = _getTextStyle(context);

    final widget = Text(
      text,
      style: textStyle.merge(style),
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
    );

    if (selectable) {
      return SelectableText(
        text,
        style: textStyle.merge(style),
        textAlign: align,
        maxLines: maxLines,
      );
    }

    return widget;
  }

  TextStyle _getTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    final color = style?.color ?? theme.textTheme.bodyMedium?.color;

    switch (type) {
      case TextType.displayLarge:
        return GoogleFonts.montserrat(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: color,
        );
      case TextType.displayMedium:
        return GoogleFonts.montserrat(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: color,
        );
      case TextType.displaySmall:
        return GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: color,
        );
      case TextType.headlineLarge:
        return GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: color,
        );
      case TextType.headlineMedium:
        return GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: color,
        );
      case TextType.headlineSmall:
        return GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: color,
        );
      case TextType.titleLarge:
        return GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: color,
        );
      case TextType.titleMedium:
        return GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
        );
      case TextType.titleSmall:
        return GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        );
      case TextType.labelLarge:
        return GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        );
      case TextType.labelMedium:
        return GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        );
      case TextType.labelSmall:
        return GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        );
      case TextType.bodyLarge:
        return GoogleFonts.openSans(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: color,
        );
      case TextType.bodyMedium:
        return GoogleFonts.openSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: color,
        );
      case TextType.bodySmall:
        return GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: color,
        );
      case TextType.caption:
        return GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: color?.withOpacity(0.7),
        );
      case TextType.button:
        return GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: color,
        );
      case TextType.quote:
        return GoogleFonts.merriweather(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          height: 1.8,
          color: color,
        );
      case TextType.code:
        return GoogleFonts.robotoMono(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          color: color,
        );
    }
  }
}

enum TextType {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  labelLarge,
  labelMedium,
  labelSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  caption,
  button,
  quote,
  code,
}