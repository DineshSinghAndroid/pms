import 'package:flutter/material.dart';

import '../theme/pms_theme.dart';

/// Inline type-to-filter picker. Uses an embedded list (not an overlay) so it
/// works inside modal bottom sheets and nested scroll views.
class SearchableTypeahead<T extends Object> extends StatefulWidget {
  final List<T> items;
  final String Function(T item) displayString;
  final bool Function(T item, String query) matches;
  final ValueChanged<T> onSelected;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final T? selected;
  final double resultsHeight;

  const SearchableTypeahead({
    super.key,
    required this.items,
    required this.displayString,
    required this.matches,
    required this.onSelected,
    this.controller,
    this.focusNode,
    this.hintText = 'Type to search...',
    this.selected,
    this.resultsHeight = 220,
  });

  @override
  State<SearchableTypeahead<T>> createState() => _SearchableTypeaheadState<T>();
}

class _SearchableTypeaheadState<T extends Object>
    extends State<SearchableTypeahead<T>> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocus = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFocus = widget.focusNode == null;
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _query = _controller.text;
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SearchableTypeahead<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_onControllerChanged);
      if (_ownsController) {
        _controller.dispose();
      }
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? TextEditingController();
      _query = _controller.text;
      _controller.addListener(_onControllerChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      final previous = _focusNode;
      final ownedPrevious = _ownsFocus;
      _ownsFocus = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      if (ownedPrevious) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          previous.dispose();
        });
      }
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_query == _controller.text) return;
    setState(() => _query = _controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFocus) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  List<T> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((item) => widget.matches(item, q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _query.isNotEmpty
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _controller.clear();
                      if (_focusNode.canRequestFocus) {
                        _focusNode.requestFocus();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.close_rounded, size: 18),
                    ),
                  )
                : null,
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
        ),
        const SizedBox(height: 8),
        Container(
          height: widget.resultsHeight,
          decoration: BoxDecoration(
            color: PmsTheme.glassSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PmsTheme.glassBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _query.trim().isEmpty
                          ? 'No products available'
                          : 'No products match "$_query"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PmsTheme.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isSelected = widget.selected == item;
                    return Material(
                      color: isSelected
                          ? PmsTheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          widget.onSelected(item);
                          _focusNode.unfocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.displayString(item),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? PmsTheme.primary
                                        : PmsTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: PmsTheme.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${filtered.length} of ${widget.items.length} products',
            style: const TextStyle(
              fontSize: 11,
              color: PmsTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
