// ============================================================
// item_search_field.dart
// ============================================================
// Smart item search field with real-time dropdown overlay.
// Filters the in-memory item list by English name OR Hindi name.
// Keyboard: ↓/↑ to navigate, Enter to select, Escape to dismiss.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/item.dart';
import '../../../theme/app_theme.dart';

class ItemSearchField extends StatefulWidget {
  /// Full list loaded once by the parent BillingScreen.
  final List<Item> allItems;

  /// Called when the user selects an item from the dropdown.
  final ValueChanged<Item> onItemSelected;

  const ItemSearchField({
    super.key,
    required this.allItems,
    required this.onItemSelected,
  });

  @override
  State<ItemSearchField> createState() => _ItemSearchFieldState();
}

class _ItemSearchFieldState extends State<ItemSearchField> {
  final _ctrl = TextEditingController();
  late final FocusNode _focusNode;
  final _overlayCtrl = OverlayPortalController();
  final _layerLink = LayerLink();
  final _anchorKey = GlobalKey();

  List<Item> _suggestions = [];
  int _highlighted = -1;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        return _handleKey(event.logicalKey);
      },
    )..addListener(_onFocusChange);

    _ctrl.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChange);
    _ctrl.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ItemSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allItems != oldWidget.allItems) {
      // Re-run search if items changed (e.g. from refresh)
      if (_ctrl.text.trim().isNotEmpty) {
        _onTextChange();
      }
    }
  }

  // ── Handlers ─────────────────────────────────────────────

  void _onTextChange() {
    final q = _ctrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      _closeDropdown();
      setState(() => _suggestions = []);
      return;
    }
    final hits = widget.allItems
        .where((item) =>
            item.name.toLowerCase().startsWith(q) ||
            (item.hindiName?.toLowerCase().startsWith(q) ?? false))
        .take(9)
        .toList();

    setState(() {
      _suggestions = hits;
      _highlighted = -1;
    });

    if (hits.isNotEmpty) {
      _openDropdown();
    } else {
      _closeDropdown();
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Small delay so a tap in the overlay registers before we close it
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted && !_focusNode.hasFocus) _closeDropdown();
      });
    }
  }

  KeyEventResult _handleKey(LogicalKeyboardKey key) {
    if (_suggestions.isEmpty) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _highlighted = (_highlighted + 1).clamp(0, _suggestions.length - 1);
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlighted = (_highlighted - 1).clamp(-1, _suggestions.length - 1);
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter && _highlighted >= 0) {
      _selectItem(_suggestions[_highlighted]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _closeDropdown();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _openDropdown() {
    if (!_overlayCtrl.isShowing) _overlayCtrl.show();
  }

  void _closeDropdown() {
    if (_overlayCtrl.isShowing) _overlayCtrl.hide();
  }

  void _selectItem(Item item) {
    widget.onItemSelected(item);
    _ctrl.clear();
    setState(() {
      _suggestions = [];
      _highlighted = -1;
    });
    _closeDropdown();
    _focusNode.requestFocus();
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlayCtrl,
      overlayChildBuilder: _buildOverlay,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TextField(
          key: _anchorKey,
          controller: _ctrl,
          focusNode: _focusNode,
          autofocus: false,
          decoration: InputDecoration(
            hintText: widget.allItems.isEmpty
                ? 'No items in database — add items in the Items screen'
                : 'Search item by name or हिंदी नाम…',
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 17),
                    color: AppColors.textSecondary,
                    onPressed: () {
                      _ctrl.clear();
                      _focusNode.requestFocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.tableBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.tableBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            hintStyle: const TextStyle(
                color: AppColors.textDisabled, fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext ctx) {
    // Measure anchor width so the dropdown exactly matches the field
    double width = 520;
    final box =
        _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) width = box.size.width;

    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _layerLink,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 6),
        showWhenUnlinked: false,
        child: SizedBox(
          width: width,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(10),
            shadowColor: Colors.black.withAlpha(40),
            child: _DropdownContent(
              suggestions: _suggestions,
              highlighted: _highlighted,
              onSelect: _selectItem,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dropdown content (separate widget for clean rebuilds) ─────

class _DropdownContent extends StatelessWidget {
  final List<Item> suggestions;
  final int highlighted;
  final ValueChanged<Item> onSelect;

  const _DropdownContent({
    required this.suggestions,
    required this.highlighted,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.tableBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column headers
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.tableHeaderBg,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 5,
                    child: Text('Item Name',
                        style: AppTextStyles.tableHeader)),
                Expanded(
                    flex: 3,
                    child: Text('हिंदी नाम',
                        style: AppTextStyles.tableHeader)),
                SizedBox(
                    width: 56,
                    child: Text('Unit',
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.center)),
                SizedBox(
                    width: 88,
                    child: Text('Price',
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.right)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Rows
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (_, i) => _SuggestionRow(
                item: suggestions[i],
                isHighlighted: i == highlighted,
                isEven: i.isEven,
                isLast: i == suggestions.length - 1,
                onTap: () => onSelect(suggestions[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatefulWidget {
  final Item item;
  final bool isHighlighted;
  final bool isEven;
  final bool isLast;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.item,
    required this.isHighlighted,
    required this.isEven,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_SuggestionRow> createState() => _SuggestionRowState();
}

class _SuggestionRowState extends State<_SuggestionRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isHighlighted
        ? AppColors.tableRowSelected
        : (_hovering
            ? AppColors.tableRowHover
            : (widget.isEven ? Colors.white : AppColors.tableRowOdd));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: bg,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // English name
              Expanded(
                flex: 5,
                child: Text(
                  widget.item.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.isHighlighted
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Hindi name
              Expanded(
                flex: 3,
                child: widget.item.hindiName != null &&
                        widget.item.hindiName!.isNotEmpty
                    ? Text(
                        widget.item.hindiName!,
                        style: GoogleFonts.notoSansDevanagari(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink(),
              ),
              // Unit
              SizedBox(
                width: 56,
                child: Text(
                  widget.item.unit,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              // Price
              SizedBox(
                width: 88,
                child: Text(
                  '₹${widget.item.sellingPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.isHighlighted
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: widget.isHighlighted
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
