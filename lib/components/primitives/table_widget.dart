import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renders a paginated DataTable from SDUI schema.
///
/// Schema: { type: "table", headers: ["Col1","Col2"], rows: [["v1","v2"]],
///   variant: "default", total_rows: 100, page_size: 10, page_offset: 0,
///   page_sizes: [10,25,50], source_tool: "tool", source_agent: "agent_id",
///   source_params: {} }
class TableWidget extends StatefulWidget {
  final Map<String, dynamic> component;
  final void Function(String action, Map<String, dynamic> payload) sendEvent;

  const TableWidget({
    required this.component,
    required this.sendEvent,
    super.key,
  });

  @override
  State<TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  late int _pageOffset;
  late int _pageSize;

  @override
  void initState() {
    super.initState();
    _pageOffset = _asInt(widget.component['page_offset'], 0);
    _pageSize = _asInt(widget.component['page_size'], 10);
  }

  @override
  void didUpdateWidget(TableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync local state when the server pushes new pagination values.
    final newOffset = _asInt(widget.component['page_offset'], _pageOffset);
    final newSize = _asInt(widget.component['page_size'], _pageSize);
    if (newOffset != _pageOffset || newSize != _pageSize) {
      setState(() {
        _pageOffset = newOffset;
        _pageSize = newSize;
      });
    }
  }

  bool get _hasPagination => widget.component['total_rows'] != null;

  int get _totalRows => _asInt(widget.component['total_rows'], 0);

  int get _totalPages =>
      _pageSize > 0 ? (_totalRows / _pageSize).ceil() : 1;

  int get _currentPage =>
      _pageSize > 0 ? (_pageOffset / _pageSize).floor() : 0;

  List<int> get _pageSizes {
    final raw = widget.component['page_sizes'];
    if (raw is List) {
      return raw.map((e) => _asInt(e, 10)).toList();
    }
    return const [10, 25, 50];
  }

  void _emitPageChange() {
    widget.sendEvent('page_change', {
      if (widget.component['source_tool'] != null)
        'source_tool': widget.component['source_tool'],
      if (widget.component['source_agent'] != null)
        'source_agent': widget.component['source_agent'],
      if (widget.component['source_params'] != null)
        'source_params': widget.component['source_params'],
      'page_offset': _pageOffset,
      'page_size': _pageSize,
    });
  }

  void _goToPage(int page) {
    final newOffset = page * _pageSize;
    if (newOffset == _pageOffset) return;
    setState(() => _pageOffset = newOffset);
    _emitPageChange();
  }

  void _changePageSize(int newSize) {
    if (newSize == _pageSize) return;
    setState(() {
      _pageSize = newSize;
      _pageOffset = 0; // Reset to first page on size change.
    });
    _emitPageChange();
  }

  @override
  Widget build(BuildContext context) {
    final headers = _castStringList(widget.component['headers']);
    final rows = widget.component['rows'] as List<dynamic>? ?? [];

    final theme = Theme.of(context);

    // Slightly lighter than surface for header distinction.
    const headerBg = Color(0xFF232840);
    // Two alternating row backgrounds for readability.
    const rowEven = AstralColors.surface; // #1A1E2E
    const rowOdd = Color(0xFF161A2A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(headerBg),
            dataRowColor: WidgetStateProperty.all(Colors.transparent),
            dividerThickness: 0.5,
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AstralColors.text.withValues(alpha: 0.9),
              letterSpacing: 0.3,
            ),
            dataTextStyle: TextStyle(
              fontSize: 13,
              color: AstralColors.text.withValues(alpha: 0.8),
            ),
            horizontalMargin: 16,
            columnSpacing: 24,
            decoration: BoxDecoration(
              color: AstralColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AstralColors.primary.withValues(alpha: 0.15),
              ),
            ),
            columns: [
              for (final header in headers)
                DataColumn(
                  label: Text(header),
                ),
            ],
            rows: [
              for (int i = 0; i < rows.length; i++)
                DataRow(
                  color: WidgetStateProperty.all(
                    i.isEven ? rowEven : rowOdd,
                  ),
                  cells: _buildCells(rows[i], headers.length),
                ),
            ],
          ),
        ),
        if (_hasPagination) _buildPaginationControls(theme),
      ],
    );
  }

  List<DataCell> _buildCells(dynamic row, int columnCount) {
    if (row is List) {
      return List.generate(columnCount, (i) {
        final value = i < row.length ? row[i] : '';
        return DataCell(Text(_stringify(value)));
      });
    }
    // Fallback: single cell spanning description.
    return List.generate(
      columnCount,
      (i) => i == 0
          ? DataCell(Text(_stringify(row)))
          : const DataCell(Text('')),
    );
  }

  Widget _buildPaginationControls(ThemeData theme) {
    final dimText = AstralColors.text.withValues(alpha: 0.55);
    final activeIcon = AstralColors.accent;
    final disabledIcon = AstralColors.text.withValues(alpha: 0.25);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page size selector
          Row(
            children: [
              Text(
                'Rows per page: ',
                style: TextStyle(fontSize: 12, color: dimText),
              ),
              DropdownButton<int>(
                value: _pageSizes.contains(_pageSize)
                    ? _pageSize
                    : _pageSizes.first,
                underline: const SizedBox.shrink(),
                dropdownColor: AstralColors.surface,
                style: TextStyle(fontSize: 12, color: AstralColors.text),
                items: [
                  for (final size in _pageSizes)
                    DropdownMenuItem(value: size, child: Text('$size')),
                ],
                onChanged: (value) {
                  if (value != null) _changePageSize(value);
                },
              ),
            ],
          ),
          // Page info and navigation
          Row(
            children: [
              Text(
                '${_pageOffset + 1}'
                '\u2013'
                '${(_pageOffset + _pageSize).clamp(0, _totalRows)}'
                ' of $_totalRows',
                style: TextStyle(fontSize: 12, color: dimText),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.first_page),
                iconSize: 20,
                color: activeIcon,
                disabledColor: disabledIcon,
                onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
                tooltip: 'First page',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                iconSize: 20,
                color: activeIcon,
                disabledColor: disabledIcon,
                onPressed: _currentPage > 0
                    ? () => _goToPage(_currentPage - 1)
                    : null,
                tooltip: 'Previous page',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                iconSize: 20,
                color: activeIcon,
                disabledColor: disabledIcon,
                onPressed: _currentPage < _totalPages - 1
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                tooltip: 'Next page',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                iconSize: 20,
                color: activeIcon,
                disabledColor: disabledIcon,
                onPressed: _currentPage < _totalPages - 1
                    ? () => _goToPage(_totalPages - 1)
                    : null,
                tooltip: 'Last page',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

int _asInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

List<String> _castStringList(dynamic value) {
  if (value is List) return value.map((e) => e?.toString() ?? '').toList();
  return const [];
}

String _stringify(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map || value is List) return jsonEncode(value);
  return value.toString();
}
