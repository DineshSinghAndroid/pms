import 'package:flutter/material.dart';

import '../theme/pms_theme.dart';

/// Type-to-filter picker used for long product / crew / asset lists.
class SearchableTypeahead<T extends Object> extends StatelessWidget {
  final List<T> items;
  final String Function(T item) displayString;
  final bool Function(T item, String query) matches;
  final ValueChanged<T> onSelected;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final int maxResults;

  const SearchableTypeahead({
    super.key,
    required this.items,
    required this.displayString,
    required this.matches,
    required this.onSelected,
    this.controller,
    this.focusNode,
    this.hintText = 'Type to search...',
    this.maxResults = 40,
  });

  Iterable<T> _optionsFor(String query) {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? items
        : items.where((item) => matches(item, q)).toList();
    if (filtered.length <= maxResults) return filtered;
    return filtered.take(maxResults);
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<T>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: displayString,
      optionsBuilder: (textEditingValue) => _optionsFor(textEditingValue.text),
      onSelected: onSelected,
      fieldViewBuilder: (context, textController, fieldFocus, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: fieldFocus,
          onSubmitted: (_) => onFieldSubmitted(),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            isDense: true,
            filled: true,
            fillColor: PmsTheme.glassSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: PmsTheme.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: PmsTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: PmsTheme.primary, width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 13, color: PmsTheme.textPrimary),
        );
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            color: PmsTheme.glassSurface,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, minWidth: 280),
              child: options.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No matching items',
                        style: TextStyle(
                          fontSize: 12,
                          color: PmsTheme.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          title: Text(
                            displayString(option),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PmsTheme.textPrimary,
                            ),
                          ),
                          onTap: () => onSelectedOption(option),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}
