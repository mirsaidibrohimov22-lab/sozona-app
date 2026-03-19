// lib/features/teacher/publishing/presentation/widgets/class_selector.dart
import 'package:flutter/material.dart';

class ClassSelectorWidget extends StatefulWidget {
  final List<String> classIds;
  final List<String> classNames;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  const ClassSelectorWidget({
    super.key,
    required this.classIds,
    required this.classNames,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  State<ClassSelectorWidget> createState() => _ClassSelectorWidgetState();
}

class _ClassSelectorWidgetState extends State<ClassSelectorWidget> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.classIds.length, (i) {
        final id = widget.classIds[i];
        final name = widget.classNames[i];
        final isSelected = _selected.contains(id);
        return CheckboxListTile(
          title: Text(name),
          value: isSelected,
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selected.add(id);
              } else {
                _selected.remove(id);
              }
            });
            widget.onChanged(_selected);
          },
        );
      }),
    );
  }
}
