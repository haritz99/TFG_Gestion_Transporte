import 'package:flutter/material.dart';

class CoreTableColumn<T> {
  final String label;
  final Widget Function(T item) cellBuilder;

  const CoreTableColumn({
    required this.label,
    required this.cellBuilder,
  });
}

