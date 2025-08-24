import 'package:flutter/material.dart';

class DictationTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSubmitted;
  final int maxLines;

  const DictationTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.maxLines = 3,
  });

  @override
  State<DictationTextField> createState() => _DictationTextFieldState();
}

class _DictationTextFieldState extends State<DictationTextField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      maxLines: widget.maxLines,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      autofocus: true,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(16),
        suffixIcon: IconButton(
          icon: const Icon(Icons.send),
          onPressed: widget.onSubmitted,
        ),
      ),
      onSubmitted: (_) => widget.onSubmitted?.call(),
    );
  }
}
