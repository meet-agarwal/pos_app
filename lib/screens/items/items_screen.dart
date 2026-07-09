// ============================================================
// items_screen.dart
// ============================================================
// State management hub for the Items Management module.
//
// Responsibilities:
//   • Load all items from the database.
//   • Apply search filter, sort, and pagination in memory.
//   • Coordinate: upload → parse Excel → import → refresh.
//   • Open dialogs for add / edit / delete.
//   • Show snack-bar feedback after operations.
//
// Rendering is delegated to focused sub-widgets:
//   EmptyItemsWidget, BulkActionBar, ItemsDataTable, dialogs.
// ============================================================

import 'dart:async';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../dao/item_dao.dart';
import '../../database/db_constants.dart';
import '../../models/item.dart';
import '../../theme/app_theme.dart';
import 'widgets/bulk_action_bar.dart';
import 'widgets/delete_confirmation_dialog.dart';
import 'widgets/empty_items_widget.dart';
import 'widgets/import_summary_dialog.dart';
import 'widgets/item_form_dialog.dart';
import 'widgets/items_data_table.dart';
import 'widgets/upload_confirmation_dialog.dart';

// ── Pagination constant ───────────────────────────────────────

const int _kItemsPerPage = 15;

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  // ── State fields ──────────────────────────────────────────

  List<Item> _allItems = [];
  bool _isLoading = true;
  bool _isImporting = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  Set<int> _selectedIds = {};

  String _sortColumn = 'name';
  bool _sortAscending = true;

  int _currentPage = 0;

  // ── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await ItemDao.instance.getAllItems();
      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
          _selectedIds = {};
          _currentPage = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load items: $e');
      }
    }
  }

  // ── Computed / derived data ───────────────────────────────

  /// Items filtered by the current search query.
  List<Item> get _filteredItems {
    if (_searchQuery.isEmpty) return _allItems;
    final q = _searchQuery.toLowerCase();
    return _allItems
        .where((item) =>
            item.name.toLowerCase().contains(q) ||
            (item.code?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  /// Filtered items with the current sort applied.
  List<Item> get _sortedItems {
    final items = List<Item>.from(_filteredItems);
    items.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'code':
          cmp = (a.code ?? '').compareTo(b.code ?? '');
          break;
        case 'hindiName':
          cmp = (a.hindiName ?? '').compareTo(b.hindiName ?? '');
          break;
        case 'groupName':
          cmp = (a.groupName ?? '').compareTo(b.groupName ?? '');
          break;
        case 'unit':
          cmp = a.unit.compareTo(b.unit);
          break;
        case 'price':
          cmp = a.sellingPrice.compareTo(b.sellingPrice);
          break;
        default: // 'name'
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return _sortAscending ? cmp : -cmp;
    });
    return items;
  }

  /// The slice of sorted items for the current page.
  List<Item> get _pagedItems {
    final sorted = _sortedItems;
    final start = _currentPage * _kItemsPerPage;
    if (start >= sorted.length) return [];
    final end = (start + _kItemsPerPage).clamp(0, sorted.length);
    return sorted.sublist(start, end);
  }

  int get _totalPages =>
      (_filteredItems.length / _kItemsPerPage).ceil().clamp(1, 999999);

  // ── Event handlers ────────────────────────────────────────

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchCtrl.text;
      _currentPage = 0; // reset to first page on new search
    });
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _currentPage = 0;
    });
  }

  void _onToggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds = Set.from(_selectedIds)..remove(id);
      } else {
        _selectedIds = Set.from(_selectedIds)..add(id);
      }
    });
  }

  void _onToggleSelectAll(bool selectAll) {
    setState(() {
      if (selectAll) {
        _selectedIds = _filteredItems
            .where((e) => e.id != null)
            .map((e) => e.id!)
            .toSet();
      } else {
        _selectedIds = {};
      }
    });
  }

  void _clearSelection() => setState(() => _selectedIds = {});

  void _onPageChanged(int page) => setState(() => _currentPage = page);

  // ── Add / Edit ────────────────────────────────────────────

  Future<void> _openAddDialog() async {
    final result = await ItemFormDialog.show(context);
    if (result == null) return;
    try {
      await ItemDao.instance.insertItem(result);
      await _loadItems();
      _showSuccess('Item "${result.name}" added successfully.');
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('UNIQUE')) {
        _showError('An item with code "${result.code}" already exists.');
      } else {
        _showError('Failed to add item: $msg');
      }
    }
  }

  Future<void> _openEditDialog(Item item) async {
    final result = await ItemFormDialog.show(context, item: item);
    if (result == null) return;
    try {
      await ItemDao.instance.updateItem(result);
      await _loadItems();
      _showSuccess('Item "${result.name}" updated.');
    } catch (e) {
      _showError('Failed to update item: $e');
    }
  }

  // ── Delete ────────────────────────────────────────────────

  Future<void> _deleteSingleItem(Item item) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      count: 1,
      itemName: item.name,
    );
    if (!confirmed) return;
    try {
      await ItemDao.instance.deleteItem(item.id!);
      await _loadItems();
      _showSuccess('"${item.name}" deleted.');
    } catch (e) {
      _showError('Failed to delete item: $e');
    }
  }

  Future<void> _deleteBulk() async {
    final ids = List<int>.from(_selectedIds);
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      count: ids.length,
    );
    if (!confirmed) return;
    try {
      await ItemDao.instance.deleteItems(ids);
      await _loadItems();
      _showSuccess('${ids.length} item(s) deleted.');
    } catch (e) {
      _showError('Failed to delete items: $e');
    }
  }

  // ── Upload / Import ───────────────────────────────────────

  Future<void> _handleUpload() async {
    // Step 1: Show the requirements confirmation dialog
    final confirmed = await UploadConfirmationDialog.show(context);
    if (!confirmed) return;

    // Step 2: Open file picker
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
        withData: true, // needed to get bytes on desktop
      );
    } catch (e) {
      _showError('Could not open file picker: $e');
      return;
    }

    if (result == null || result.files.isEmpty) return; // user cancelled
    final file = result.files.first;

    // Step 3: Validate file has bytes
    if (file.bytes == null || file.bytes!.isEmpty) {
      _showError('Could not read the selected file.');
      return;
    }

    setState(() => _isImporting = true);

    try {
      // Step 4: Decode Excel
      final Excel excel;
      try {
        excel = Excel.decodeBytes(file.bytes!);
      } catch (_) {
        _showError('Invalid or corrupted Excel file.');
        return;
      }

      if (excel.tables.isEmpty) {
        _showError('The Excel file contains no worksheets.');
        return;
      }

      // Step 5: Read only the first worksheet
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (sheet.rows.isEmpty) {
        _showError('The spreadsheet is empty.');
        return;
      }

      // Step 6: Validate the header row (exact order required)
      // New column order: code | name | hindi_name | group_name | unit | selling_price
      final expectedHeaders = [
        ItemColumns.code,
        ItemColumns.name,
        ItemColumns.hindiName,
        ItemColumns.groupName,
        ItemColumns.unit,
        ItemColumns.sellingPrice,
      ];

      final headerRow = sheet.rows.first;
      final headerError = _validateHeader(headerRow, expectedHeaders);
      if (headerError != null) {
        _showError(headerError);
        return;
      }

      // Step 7: Parse data rows into string maps
      // Column positions: 0=code, 1=name, 2=hindi_name, 3=group_name, 4=unit, 5=selling_price
      final dataRows = <Map<String, String>>[];
      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        // Skip completely empty rows
        if (row.every((cell) =>
            cell == null || _cellToString(cell).isEmpty)) {
          continue;
        }
        dataRows.add({
          ItemColumns.code:         _cellToString(row.length > 0 ? row[0] : null),
          ItemColumns.name:         _cellToString(row.length > 1 ? row[1] : null),
          ItemColumns.hindiName:    _cellToString(row.length > 2 ? row[2] : null),
          ItemColumns.groupName:    _cellToString(row.length > 3 ? row[3] : null),
          ItemColumns.unit:         _cellToString(row.length > 4 ? row[4] : null),
          ItemColumns.sellingPrice: _cellToString(row.length > 5 ? row[5] : null),
        });
      }

      if (dataRows.isEmpty) {
        _showError('No data rows found (only a header row was present).');
        return;
      }

      // Step 8: Bulk import via DAO
      final summary = await ItemDao.instance.bulkImport(dataRows);

      // Step 9: Refresh the table
      await _loadItems();

      // Step 10: Show the import summary dialog
      if (mounted) {
        await ImportSummaryDialog.show(context, summary);
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // ── Excel parsing helpers ─────────────────────────────────

  /// Validates that the header row has exactly the expected column names.
  /// Returns an error message string, or null if valid.
  String? _validateHeader(
      List<Data?> headerRow, List<String> expectedHeaders) {
    if (headerRow.length < expectedHeaders.length) {
      return 'The spreadsheet has fewer columns than required. '
          'Expected: ${expectedHeaders.join(", ")}';
    }
    for (int i = 0; i < expectedHeaders.length; i++) {
      final actual = _cellToString(headerRow[i]);
      if (actual != expectedHeaders[i]) {
        return 'Column ${i + 1} mismatch: expected "${expectedHeaders[i]}" '
            'but found "$actual". Column names must match exactly.';
      }
    }
    return null;
  }

  /// Safely converts a [Data] cell to a plain string.
  String _cellToString(Data? cell) {
    if (cell == null) return '';
    final value = cell.value;
    if (value == null) return '';
    if (value is TextCellValue) return value.value.toString().trim();
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    if (value is BoolCellValue) return value.value.toString();
    return value.toString().trim();
  }

  // ── Snackbar helpers ──────────────────────────────────────

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildScreenHeader(),
        const Divider(),
        _buildActionBar(),
        if (_selectedIds.isNotEmpty) _buildBulkBar(),
        if (_isImporting) _buildImportingBanner(),
        if (_isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_allItems.isEmpty)
          Expanded(child: EmptyItemsWidget(onUpload: _handleUpload))
        else
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tableBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ItemsDataTable(
                  pagedItems: _pagedItems,
                  allFilteredItems: _filteredItems,
                  selectedIds: _selectedIds,
                  sortColumn: _sortColumn,
                  sortAscending: _sortAscending,
                  onSort: _onSort,
                  onToggleSelect: _onToggleSelect,
                  onToggleSelectAll: _onToggleSelectAll,
                  onEdit: _openEditDialog,
                  onDelete: _deleteSingleItem,
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  totalItems: _filteredItems.length,
                  itemsPerPage: _kItemsPerPage,
                  onPageChanged: _onPageChanged,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Sub-sections of the screen ────────────────────────────

  Widget _buildScreenHeader() {
    return Container(
      height: 64,
      color: AppColors.screenHeaderBg,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text('Items', style: AppTextStyles.screenTitle),
          const Spacer(),
          // Item count badge
          if (_allItems.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_allItems.length} item${_allItems.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search by item name or code…',
                  prefixIcon:
                      Icon(Icons.search, size: 20, color: AppColors.textDisabled),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Add item button
          ElevatedButton.icon(
            onPressed: _openAddDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Item'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 8),

          // Upload button
          OutlinedButton.icon(
            onPressed: _isImporting ? null : _handleUpload,
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text('Upload Sheet'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkBar() {
    return BulkActionBar(
      selectedCount: _selectedIds.length,
      onDeleteSelected: _deleteBulk,
      onClearSelection: _clearSelection,
    );
  }

  Widget _buildImportingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primaryLight,
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Importing items, please wait…',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
