import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:ngekas/services/database_service.dart';
import 'package:xml/xml.dart';

// ─── SpreadsheetReader ──────────────────────────────────────────────────────
//
// Baca file .csv / .xlsx jadi tabel teks (List baris -> List sel). Sengaja
// ditulis sendiri (bukan package `excel`) karena package Excel yang ada
// bentrok versi `xml` dengan package `pdf`. File .xlsx = zip berisi XML:
// cukup baca shared strings + sheet pertama. Yang dibaca hanya nilai sel
// (bukan rumus/format).

class SpreadsheetReader {
  SpreadsheetReader._();

  static List<List<String>> read(String fileName, Uint8List bytes) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.xlsx')) return parseXlsx(bytes);
    if (lower.endsWith('.csv') || lower.endsWith('.txt')) return parseCsv(utf8.decode(bytes, allowMalformed: true));
    throw DataException('Format file tidak didukung. Pakai .xlsx atau .csv');
  }

  // ─── CSV ──────────────────────────────────────────────────────────────────

  // Pemisah dideteksi otomatis (, ; atau tab) — Excel berbahasa Indonesia
  // biasanya menyimpan CSV dengan ';'. Baris "sep=," dari Excel dilewati.
  static List<List<String>> parseCsv(String input) {
    var text = input.replaceFirst('﻿', '').replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    String? delimiter;
    final firstLineEnd = text.indexOf('\n');
    final firstLine = firstLineEnd == -1 ? text : text.substring(0, firstLineEnd);
    if (firstLine.toLowerCase().startsWith('sep=') && firstLine.length >= 5) {
      delimiter = firstLine[4];
      text = firstLineEnd == -1 ? '' : text.substring(firstLineEnd + 1);
    }
    delimiter ??= _detectDelimiter(firstLine);

    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          cell.write(char);
        }
      } else if (char == '"') {
        inQuotes = true;
      } else if (char == delimiter) {
        row.add(cell.toString().trim());
        cell.clear();
      } else if (char == '\n') {
        row.add(cell.toString().trim());
        cell.clear();
        rows.add(row);
        row = <String>[];
      } else {
        cell.write(char);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString().trim());
      rows.add(row);
    }
    return rows;
  }

  static String _detectDelimiter(String line) {
    final counts = {for (final d in [',', ';', '\t']) d: d.allMatches(line).length};
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // ─── XLSX ─────────────────────────────────────────────────────────────────

  static List<List<String>> parseXlsx(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw DataException('File Excel tidak bisa dibaca. Pastikan formatnya .xlsx (bukan .xls lama)');
    }

    final shared = <String>[];
    final sharedFile = archive.findFile('xl/sharedStrings.xml');
    if (sharedFile != null) {
      final doc = XmlDocument.parse(utf8.decode(sharedFile.content));
      for (final si in doc.findAllElements('si')) {
        shared.add(si.findAllElements('t').map((t) => t.innerText).join());
      }
    }

    final sheetFile = archive.findFile(_firstSheetPath(archive) ?? '') ??
        archive.files.where((f) => f.name.startsWith('xl/worksheets/sheet') && f.name.endsWith('.xml')).firstOrNull;
    if (sheetFile == null) throw DataException('Sheet di file Excel tidak ditemukan');

    final doc = XmlDocument.parse(utf8.decode(sheetFile.content));
    final rows = <List<String>>[];
    for (final rowEl in doc.findAllElements('row')) {
      final cells = <int, String>{};
      var nextIndex = 0;
      for (final c in rowEl.findElements('c')) {
        final ref = c.getAttribute('r');
        final index = ref == null ? nextIndex : _columnIndex(ref);
        nextIndex = index + 1;
        final type = c.getAttribute('t');
        final raw = c.findElements('v').firstOrNull?.innerText ?? '';
        final value = switch (type) {
          's' => (int.tryParse(raw) ?? -1) >= 0 && int.parse(raw) < shared.length ? shared[int.parse(raw)] : '',
          'inlineStr' => c.findAllElements('t').map((t) => t.innerText).join(),
          'b' => raw == '1' ? 'TRUE' : 'FALSE',
          'str' || 'e' => raw,
          _ => _formatNumber(raw),
        };
        cells[index] = value.trim();
      }
      if (cells.isEmpty) {
        rows.add([]);
        continue;
      }
      final maxIndex = cells.keys.reduce((a, b) => a > b ? a : b);
      rows.add([for (var i = 0; i <= maxIndex; i++) cells[i] ?? '']);
    }
    return rows;
  }

  // Path sheet pertama menurut workbook.xml + relasinya.
  static String? _firstSheetPath(Archive archive) {
    final workbook = archive.findFile('xl/workbook.xml');
    final rels = archive.findFile('xl/_rels/workbook.xml.rels');
    if (workbook == null || rels == null) return null;
    final sheet = XmlDocument.parse(utf8.decode(workbook.content)).findAllElements('sheet').firstOrNull;
    final relId = sheet?.attributes.where((a) => a.name.local == 'id').firstOrNull?.value;
    if (relId == null) return null;
    for (final rel in XmlDocument.parse(utf8.decode(rels.content)).findAllElements('Relationship')) {
      if (rel.getAttribute('Id') == relId) {
        final target = rel.getAttribute('Target') ?? '';
        return target.startsWith('/') ? target.substring(1) : 'xl/$target';
      }
    }
    return null;
  }

  // "B12" -> 1.
  static int _columnIndex(String ref) {
    var index = 0;
    for (final unit in ref.toUpperCase().codeUnits) {
      if (unit < 65 || unit > 90) break;
      index = index * 26 + (unit - 64);
    }
    return index - 1;
  }

  // Angka dari Excel: "55000.0" -> "55000", "8.997011930011E12" -> "8997011930011".
  static String _formatNumber(String raw) {
    if (raw.isEmpty) return '';
    final number = double.tryParse(raw);
    if (number == null) return raw;
    if (number == number.roundToDouble() && number.abs() < 1e15) return number.toStringAsFixed(0);
    return raw;
  }
}
