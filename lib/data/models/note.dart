import 'package:flutter/material.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final String? deltaJson; // quill delta (rich text + image embeds)
  final List<String> tags;
  final String? category;
  final DateTime date;
  final Color color;
  final String? imageUrl;
  final bool isPinned;
  final bool isLocked;
  final bool isBookmarked; // NEW
  final bool isChecklist;
  final List<ChecklistItem>? checklistItems;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.deltaJson,
    this.tags = const [],
    this.category,
    required this.date,
    required this.color,
    this.imageUrl,
    this.isPinned = false,
    this.isLocked = false,
    this.isBookmarked = false, // NEW
    this.isChecklist = false,
    this.checklistItems,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? deltaJson,
    List<String>? tags,
    String? category,
    DateTime? date,
    Color? color,
    String? imageUrl,
    bool? isPinned,
    bool? isLocked,
    bool? isBookmarked, // NEW
    bool? isChecklist,
    List<ChecklistItem>? checklistItems,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      deltaJson: deltaJson ?? this.deltaJson,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      date: date ?? this.date,
      color: color ?? this.color,
      imageUrl: imageUrl ?? this.imageUrl,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      isBookmarked: isBookmarked ?? this.isBookmarked, // NEW
      isChecklist: isChecklist ?? this.isChecklist,
      checklistItems: checklistItems ?? this.checklistItems,
    );
  }
}

class ChecklistItem {
  final String text;
  final bool isDone;

  const ChecklistItem({required this.text, this.isDone = false});
}
