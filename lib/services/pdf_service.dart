import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/bead_color.dart';
import '../models/pattern_data.dart';
import '../models/plate_shape.dart';

class PdfService {
  /// Generate a PDF document for a bead pattern.
  /// Returns PDF bytes.
  static Future<Uint8List> generate(PatternData pattern) async {
    final pdf = pw.Document();
    final settings = pattern.settings;
    final isHex = settings.shape == PlateShape.hexagon;
    final beadMm = settings.brand.beadDiameterMm;

    // Grid dimensions
    final cols = pattern.columns;
    final rows = pattern.rows;

    // Cell size in points (1mm = 2.83465pt)
    final mmToPt = PdfPageFormat.mm;
    final cellPt = beadMm * mmToPt;

    // Calculate page dimensions for real-size output
    final gridWidthPt = isHex ? cols * cellPt + cellPt * 0.5 : cols * cellPt;
    final gridHeightPt = isHex ? rows * cellPt * 0.866 + cellPt : rows * cellPt;

    // Use A4 with auto-tiling if grid exceeds page
    final pageFormat = PdfPageFormat.a4;
    final usableW = pageFormat.width - 40; // 20pt margin each side
    final usableH = pageFormat.height - 60; // margins + header

    // If grid fits on one page, use fitted size; otherwise tile
    final fitsOnPage = gridWidthPt <= usableW && gridHeightPt <= usableH;
    final scale = fitsOnPage
        ? 1.0
        : (usableW / gridWidthPt).clamp(0, 1.0) < (usableH / gridHeightPt).clamp(0, 1.0)
            ? usableW / gridWidthPt
            : usableH / gridHeightPt;

    final drawCellPt = cellPt * scale;

    // Overview page with pattern
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                'beadot',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${settings.brand.displayNameEn} / ${settings.shape.displayNameEn} ${settings.size.label} / '
                '${settings.size.displaySize} / ${pattern.usedColorCount} colors / ${pattern.totalBeads} beads',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 12),

              // Grid
              pw.Expanded(
                child: pw.Center(
                  child: isHex
                      ? _buildHexGrid(pattern, drawCellPt)
                      : _buildSquareGrid(pattern, drawCellPt),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Color legend page
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          final beadCounts = pattern.beadCounts;
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Color List', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FixedColumnWidth(24),
                  2: const pw.FlexColumnWidth(),
                  3: const pw.FixedColumnWidth(40),
                  4: const pw.FixedColumnWidth(50),
                },
                children: [
                  // Header
                  pw.TableRow(
                    children: ['#', 'Sym', 'Color', 'ID', 'Count'].map((h) =>
                      pw.Container(
                        padding: const pw.EdgeInsets.all(3),
                        color: PdfColors.grey200,
                        child: pw.Text(h, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                      ),
                    ).toList(),
                  ),
                  // Data rows
                  ...beadCounts.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final color = entry.value.key;
                    final count = entry.value.value;
                    return pw.TableRow(
                      children: [
                        _cellText('$idx'),
                        _cellText(color.symbol),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 10, height: 10,
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex(color.hex.replaceFirst('#', '')),
                                  border: pw.Border.all(color: PdfColors.grey400, width: 0.3),
                                ),
                              ),
                              pw.SizedBox(width: 4),
                              pw.Expanded(child: pw.Text(color.nameEn, style: const pw.TextStyle(fontSize: 7))),
                            ],
                          ),
                        ),
                        _cellText(color.id),
                        _cellText('$count'),
                      ],
                    );
                  }),
                  // Total row
                  pw.TableRow(
                    children: [
                      _cellText(''),
                      _cellText(''),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                      ),
                      _cellText('${pattern.usedColorCount}'),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('${pattern.totalBeads}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSquareGrid(PatternData pattern, double cellPt) {
    final rows = pattern.rows;
    final cols = pattern.columns;

    return pw.CustomPaint(
      size: PdfPoint(cols * cellPt, rows * cellPt),
      painter: (PdfGraphics canvas, PdfPoint size) {
        for (int y = 0; y < rows; y++) {
          for (int x = 0; x < cols; x++) {
            final color = pattern.colorAt(y, x);
            final left = x * cellPt;
            final top = (rows - 1 - y) * cellPt; // PDF Y is bottom-up

            // Grid line
            canvas
              ..setStrokeColor(PdfColors.grey300)
              ..setLineWidth(0.3)
              ..drawRect(left, top, cellPt, cellPt)
              ..strokePath();

            if (color == null) continue;

            // Fill
            canvas
              ..setFillColor(PdfColor.fromHex(color.hex.replaceFirst('#', '')))
              ..drawRect(left + 0.5, top + 0.5, cellPt - 1, cellPt - 1)
              ..fillPath();

            // Symbol
            if (cellPt >= 6) {
              canvas
                ..setFillColor(color.luminance > 0.5 ? PdfColors.black : PdfColors.white);
              // Simple text positioning (approximate)
              final fontSize = cellPt * 0.55;
              canvas.drawString(
                PdfFont.courier(canvas.pdfDocument!),
                fontSize,
                color.symbol,
                left + cellPt * 0.25,
                top + cellPt * 0.2,
              );
            }
          }
        }
      },
    );
  }

  static pw.Widget _buildHexGrid(PatternData pattern, double cellPt) {
    final rows = pattern.rows;
    final cols = pattern.columns;
    final rowHeight = cellPt * 0.866;

    return pw.CustomPaint(
      size: PdfPoint(cols * cellPt + cellPt * 0.5, rows * rowHeight + cellPt),
      painter: (PdfGraphics canvas, PdfPoint size) {
        for (int y = 0; y < rows; y++) {
          final isOddRow = y % 2 == 1;
          final xOffset = isOddRow ? cellPt * 0.5 : 0.0;
          final pdfY = size.y - (y * rowHeight + cellPt / 2) - cellPt / 2;

          for (int x = 0; x < cols; x++) {
            final color = pattern.colorAt(y, x);
            if (color == null) continue;

            final cx = x * cellPt + cellPt / 2 + xOffset;

            // Fill circle
            canvas
              ..setFillColor(PdfColor.fromHex(color.hex.replaceFirst('#', '')))
              ..drawEllipse(cx, pdfY + cellPt / 2, cellPt * 0.45, cellPt * 0.45)
              ..fillPath();

            // Symbol
            if (cellPt >= 6) {
              canvas
                ..setFillColor(color.luminance > 0.5 ? PdfColors.black : PdfColors.white);
              final fontSize = cellPt * 0.4;
              canvas.drawString(
                PdfFont.courier(canvas.pdfDocument!),
                fontSize,
                color.symbol,
                cx - cellPt * 0.15,
                pdfY + cellPt * 0.3,
              );
            }
          }
        }
      },
    );
  }

  static pw.Widget _cellText(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 7)),
    );
  }
}
