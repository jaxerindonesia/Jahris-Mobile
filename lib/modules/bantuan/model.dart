import 'package:flutter/material.dart';

class HelpCategory {
  const HelpCategory({
    required this.id,
    required this.label,
    required this.iconAsset,
    required this.color,
  });

  final String id;
  final String label;
  final String iconAsset;
  final Color color;
}

class FaqItem {
  const FaqItem({
    required this.question,
    required this.answer,
    required this.categoryId,
  });

  final String question;
  final String answer;
  final String categoryId;
}
