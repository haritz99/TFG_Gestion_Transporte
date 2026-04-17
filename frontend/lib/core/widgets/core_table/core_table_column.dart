import 'package:flutter/material.dart';

class CoreTableColumn<T> {
  final String label;
  final int flex;
  final Widget Function(T item) cellBuilder;

  const CoreTableColumn({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
  });
}
