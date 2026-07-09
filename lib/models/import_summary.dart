// ============================================================
// import_summary.dart
// ============================================================
// Simple data class returned by ItemDao.bulkImport().
// Carries the result counts and any per-row error messages.
// ============================================================

class ImportSummary {
  final int totalRows;
  final int imported;  // new rows added
  final int updated;   // existing rows updated
  final int failed;    // rows that were skipped due to errors
  final List<String> errors; // human-readable error per bad row

  const ImportSummary({
    required this.totalRows,
    required this.imported,
    required this.updated,
    required this.failed,
    this.errors = const [],
  });

  /// True when at least one row failed.
  bool get hasErrors => errors.isNotEmpty;

  /// Total successfully processed rows (new + updated).
  int get successful => imported + updated;
}
