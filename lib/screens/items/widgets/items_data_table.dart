// ============================================================
// items_data_table.dart
// ============================================================
// Renders the items table with:
//   • Sticky header row with sort indicators
//   • Alternating row colors + hover highlight
//   • Per-row checkbox for selection
//   • Select-all / deselect-all header checkbox
//   • Inline Edit and Delete buttons (appear on hover or selection)
//   • Pagination controls at the bottom
// ============================================================

import 'package:flutter/material.dart';
import '../../../models/item.dart';
import '../../../theme/app_theme.dart';

// ── Column layout constants ───────────────────────────────────

const double _checkboxW = 52;
const double _rowHeight = 52;
const double _headerHeight = 44;

class ItemsDataTable extends StatefulWidget {
  /// The items to display on the current page (already filtered & sorted).
  final List<Item> pagedItems;

  /// ALL filtered items (used for select-all logic).
  final List<Item> allFilteredItems;

  final Set<int> selectedIds;
  final String sortColumn;
  final bool sortAscending;

  final void Function(String column) onSort;
  final void Function(int id) onToggleSelect;
  final void Function(bool selectAll) onToggleSelectAll;
  final void Function(Item item) onEdit;
  final void Function(Item item) onDelete;

  // Pagination
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final void Function(int page) onPageChanged;

  const ItemsDataTable({
    super.key,
    required this.pagedItems,
    required this.allFilteredItems,
    required this.selectedIds,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.onToggleSelect,
    required this.onToggleSelectAll,
    required this.onEdit,
    required this.onDelete,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  @override
  State<ItemsDataTable> createState() => _ItemsDataTableState();
}

class _ItemsDataTableState extends State<ItemsDataTable> {
  int? _hoveredId;

  // ── Select-all tri-state ──────────────────────────────────
  bool? get _selectAllState {
    final allIds =
        widget.allFilteredItems.map((e) => e.id!).toSet();
    if (widget.selectedIds.isEmpty) return false;
    if (allIds.every(widget.selectedIds.contains)) return true;
    return null; // indeterminate
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sticky header
        _buildHeader(),
        const Divider(height: 1),

        // Scrollable rows
        Expanded(
          child: widget.pagedItems.isEmpty
              ? const Center(
                  child: Text(
                    'No items match your search.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  itemCount: widget.pagedItems.length,
                  itemBuilder: (_, i) =>
                      _buildRow(widget.pagedItems[i], i),
                ),
        ),

        // Pagination
        const Divider(height: 1),
        _buildPagination(),
      ],
    );
  }

  // ── Header row ────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      height: _headerHeight,
      color: AppColors.tableHeaderBg,
      child: Row(
        children: [
          // Select-all checkbox
          SizedBox(
            width: _checkboxW,
            child: Checkbox(
              tristate: true,
              value: _selectAllState,
              onChanged: (v) =>
                  widget.onToggleSelectAll(v == true),
            ),
          ),
          _HeaderCell(
              label: 'Code',
              column: 'code',
              flex: 2,
              sortColumn: widget.sortColumn,
              sortAscending: widget.sortAscending,
              onSort: widget.onSort),
          _HeaderCell(
              label: 'Item Name',
              column: 'name',
              flex: 4,
              sortColumn: widget.sortColumn,
              sortAscending: widget.sortAscending,
              onSort: widget.onSort),
          _HeaderCell(
              label: 'Hindi Name',
              column: 'hindiName',
              flex: 3,
              sortColumn: widget.sortColumn,
              sortAscending: widget.sortAscending,
              onSort: widget.onSort),
          _HeaderCell(
              label: 'Group',
              column: 'groupName',
              flex: 2,
              sortColumn: widget.sortColumn,
              sortAscending: widget.sortAscending,
              onSort: widget.onSort),
          _HeaderCell(
              label: 'Unit',
              column: 'unit',
              flex: 2,
              sortColumn: widget.sortColumn,
              sortAscending: widget.sortAscending,
              onSort: widget.onSort),
          _HeaderCell(
              label: 'Price',
              column: 'price',
              flex: 2,
              sortColumn: widget.sortColumn,
              sortAscending: widget.sortAscending,
              onSort: widget.onSort,
              rightAlign: true),
          // Actions column header
          const SizedBox(
            width: 100,
            child: Center(
              child: Text('Actions',
                  style: AppTextStyles.tableHeader),
            ),
          ),
        ],
      ),
    );
  }

  // ── Data row ──────────────────────────────────────────────

  Widget _buildRow(Item item, int index) {
    final isSelected = widget.selectedIds.contains(item.id);
    final isHovered = _hoveredId == item.id;
    final isEven = index % 2 == 0;

    Color rowColor;
    if (isSelected) {
      rowColor = AppColors.tableRowSelected;
    } else if (isHovered) {
      rowColor = AppColors.tableRowHover;
    } else {
      rowColor = isEven ? AppColors.tableRowEven : AppColors.tableRowOdd;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredId = item.id),
      onExit: (_) => setState(() => _hoveredId = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: _rowHeight,
        color: rowColor,
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: _checkboxW,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => widget.onToggleSelect(item.id!),
              ),
            ),

            // Code — monospaced
            Expanded(
              flex: 2,
              child: _Cell(
                text: item.code ?? '—',
                style: AppTextStyles.tableCellMono,
              ),
            ),

            // Name
            Expanded(
              flex: 4,
              child: _Cell(text: item.name),
            ),

            // Hindi Name
            Expanded(
              flex: 3,
              child: _Cell(
                text: item.hindiName ?? '',
                style: AppTextStyles.tableCell.copyWith(
                    color: item.hindiName != null
                        ? AppColors.textPrimary
                        : AppColors.textDisabled),
              ),
            ),

            // Group
            Expanded(
              flex: 2,
              child: item.groupName != null
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.groupName!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : const SizedBox(),
            ),

            // Unit
            Expanded(
              flex: 2,
              child: _Cell(text: item.unit),
            ),

            // Price — right-aligned
            Expanded(
              flex: 2,
              child: _Cell(
                text: '₹ ${item.sellingPrice.toStringAsFixed(2)}',
                rightAlign: true,
              ),
            ),

            // Action buttons (always visible but styled subtly)
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    tooltip: 'Edit',
                    onTap: () => widget.onEdit(item),
                  ),
                  const SizedBox(width: 4),
                  _ActionBtn(
                    icon: Icons.delete_outline,
                    color: AppColors.error,
                    tooltip: 'Delete',
                    onTap: () => widget.onDelete(item),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pagination controls ───────────────────────────────────

  Widget _buildPagination() {
    final start =
        widget.totalItems == 0 ? 0 : widget.currentPage * widget.itemsPerPage + 1;
    final end = (start + widget.itemsPerPage - 1).clamp(0, widget.totalItems);

    return Container(
      height: 52,
      color: AppColors.tableHeaderBg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            widget.totalItems == 0
                ? 'No items'
                : 'Showing $start–$end of ${widget.totalItems} items',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const Spacer(),

          // Page number buttons
          ..._buildPageButtons(),

          const SizedBox(width: 8),
          _PaginationBtn(
            icon: Icons.chevron_right,
            enabled: widget.currentPage < widget.totalPages - 1,
            onTap: () => widget.onPageChanged(widget.currentPage + 1),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageButtons() {
    if (widget.totalPages <= 1) return [];

    final pages = <Widget>[
      _PaginationBtn(
        icon: Icons.chevron_left,
        enabled: widget.currentPage > 0,
        onTap: () => widget.onPageChanged(widget.currentPage - 1),
      ),
      const SizedBox(width: 4),
    ];

    // Show up to 5 page buttons, centred around the current page
    final int totalPages = widget.totalPages;
    int start = (widget.currentPage - 2).clamp(0, totalPages);
    int end = (start + 5).clamp(0, totalPages);
    if (end - start < 5) start = (end - 5).clamp(0, end);

    for (int p = start; p < end; p++) {
      final isCurrent = p == widget.currentPage;
      pages.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: isCurrent ? null : () => widget.onPageChanged(p),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    isCurrent ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${p + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isCurrent
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return pages;
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  final String label;
  final String column;
  final int flex;
  final String sortColumn;
  final bool sortAscending;
  final bool rightAlign;
  final void Function(String) onSort;

  const _HeaderCell({
    required this.label,
    required this.column,
    required this.flex,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    this.rightAlign = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = sortColumn == column;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort(column),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: rightAlign
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.tableHeader),
              const SizedBox(width: 4),
              Icon(
                isActive
                    ? (sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                    : Icons.unfold_more,
                size: 14,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool rightAlign;
  final TextStyle? style;

  const _Cell({required this.text, this.rightAlign = false, this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        style: style ?? AppTextStyles.tableCell,
        overflow: TextOverflow.ellipsis,
        textAlign: rightAlign ? TextAlign.right : TextAlign.left,
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}

class _PaginationBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.tableHeaderBg
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.tableBorder),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.textSecondary
              : AppColors.textDisabled,
        ),
      ),
    );
  }
}
