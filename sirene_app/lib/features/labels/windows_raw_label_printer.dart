import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'label_printer_transport.dart';

/// Lista impressoras instaladas no spooler Windows.
List<String> listWindowsPrinters() {
  if (!Platform.isWindows) return [];

  final bytesNeeded = calloc<DWORD>();
  final count = calloc<DWORD>();
  try {
    EnumPrinters(
      PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS,
      nullptr,
      2,
      nullptr,
      0,
      bytesNeeded,
      count,
    );

    if (bytesNeeded.value == 0) return [];

    final buffer = calloc<Uint8>(bytesNeeded.value);
    try {
      final ok = EnumPrinters(
        PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS,
        nullptr,
        2,
        buffer,
        bytesNeeded.value,
        bytesNeeded,
        count,
      );
      if (ok == 0) return [];

      final info = buffer.cast<PRINTER_INFO_2>();
      final names = <String>[];
      for (var i = 0; i < count.value; i++) {
        final name = info.elementAt(i).ref.pPrinterName.toDartString();
        if (name.isNotEmpty) names.add(name);
      }
      names.sort();
      return names;
    } finally {
      free(buffer);
    }
  } finally {
    free(bytesNeeded);
    free(count);
  }
}

class WindowsRawLabelPrinter implements LabelPrinterTransport {
  WindowsRawLabelPrinter({required this.printerName});

  final String printerName;

  @override
  String get modeDescription => 'USB ($printerName)';

  @override
  Future<void> sendZpl(String zpl) async {
    if (!Platform.isWindows) {
      throw UnsupportedError('Impressão USB só está disponível no Windows');
    }
    await Future<void>(() => _sendRawSync(zpl));
  }

  void _sendRawSync(String zpl) {
    final printerNamePtr = printerName.toNativeUtf16();
    final hPrinter = calloc<HANDLE>();
    final docName = 'Sirene ZPL'.toNativeUtf16();
    final dataType = 'RAW'.toNativeUtf16();
    final docInfo = calloc<DOC_INFO_1>();

    try {
      if (OpenPrinter(printerNamePtr, hPrinter, nullptr) == 0) {
        throw StateError('Impressora não encontrada: $printerName');
      }

      docInfo.ref
        ..pDocName = docName
        ..pOutputFile = nullptr
        ..pDatatype = dataType;

      if (StartDocPrinter(hPrinter.value, 1, docInfo.cast()) == 0) {
        throw StateError('Falha ao iniciar job na impressora');
      }

      if (StartPagePrinter(hPrinter.value) == 0) {
        EndDocPrinter(hPrinter.value);
        throw StateError('Falha ao iniciar página na impressora');
      }

      final bytes = ascii.encode(zpl);
      final data = calloc<Uint8>(bytes.length);
      final written = calloc<DWORD>();
      try {
        for (var i = 0; i < bytes.length; i++) {
          data[i] = bytes[i];
        }
        if (WritePrinter(hPrinter.value, data.cast(), bytes.length, written) == 0) {
          throw StateError('Falha ao enviar ZPL à impressora');
        }
      } finally {
        free(data);
        free(written);
      }

      EndPagePrinter(hPrinter.value);
      EndDocPrinter(hPrinter.value);
    } finally {
      if (hPrinter.value != 0) {
        ClosePrinter(hPrinter.value);
      }
      free(printerNamePtr);
      free(docName);
      free(dataType);
      free(docInfo);
      free(hPrinter);
    }
  }
}
