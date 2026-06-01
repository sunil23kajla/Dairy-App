import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrintHelper {
  // Singleton Pattern
  static final PrintHelper _instance = PrintHelper._internal();
  factory PrintHelper() => _instance;
  PrintHelper._internal();

  String? _savedMacAddress;

  // Retrieve saved printer address
  Future<String?> getSavedPrinter() async {
    if (_savedMacAddress != null) return _savedMacAddress;
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedMacAddress = prefs.getString('saved_printer_mac');
    } catch (_) {}
    return _savedMacAddress;
  }

  // Scan paired devices
  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      return [];
    }
  }

  // Check connection status
  Future<bool> isConnected() async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (_) {
      return false;
    }
  }

  // Connect to printer
  Future<bool> connect(String macAddress) async {
    try {
      final connected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      if (connected) {
        _savedMacAddress = macAddress;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_printer_mac', macAddress);
      }
      return connected;
    } catch (_) {
      return false;
    }
  }

  // Disconnect printer
  Future<bool> disconnect() async {
    try {
      final disconnected = await PrintBluetoothThermal.disconnect;
      if (disconnected) {
        _savedMacAddress = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_printer_mac');
      }
      return disconnected;
    } catch (_) {
      return false;
    }
  }

  // Auto connect to saved printer on app start
  Future<bool> autoConnect() async {
    final mac = await getSavedPrinter();
    if (mac != null) {
      final alreadyConnected = await isConnected();
      if (alreadyConnected) return true;
      return await connect(mac);
    }
    return false;
  }

  // Helper to remove Hindi/Unicode special characters for standard printers,
  // or print them if supported. Thermal printers typically do not support Hindi/UTF-8
  // natively without graphic bitmap printing. Thus, B2B thermal receipts are printed
  // in clean English format, which is standard in India.
  // We will provide clear English labels.
  
  // Print Milk Collection Slip (ESC/POS 58mm format)
  Future<bool> printMilkCollectionSlip({
    required String dairyName,
    required String dairyCode,
    required String farmerId,
    required String farmerName,
    required DateTime date,
    required String session,
    required double liters,
    required double? fat,
    required double? snf,
    required double rate,
    required double totalAmount,
  }) async {
    final connected = await isConnected();
    if (!connected) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Header
      bytes += generator.reset();
      bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text(dairyName.replaceAll(RegExp(r'\([^\)]*\)'), '').trim()); // Strip hindi translations in braces
      bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: false, height: PosTextSize.size1, width: PosTextSize.size1));
      bytes += generator.text("CODE: $dairyCode");
      bytes += generator.text("================================"); // 32 chars divider

      // Date, Session
      final dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      bytes += generator.text("Date: $dateStr    Time: $timeStr");
      bytes += generator.text("Shift: ${session.toUpperCase()}");
      bytes += generator.text("--------------------------------");

      // Farmer Details
      bytes += generator.text("Farmer ID  : $farmerId");
      bytes += generator.text("Name       : $farmerName");
      bytes += generator.text("--------------------------------");

      // Collection metrics
      bytes += generator.text("Quantity   : ${liters.toStringAsFixed(2)} Liters");
      if (fat == null || snf == null) {
        bytes += generator.text("FAT        : PENDING");
        bytes += generator.text("SNF        : PENDING");
        bytes += generator.text("Rate       : PENDING");
        bytes += generator.text("--------------------------------");
        bytes += generator.setStyles(const PosStyles(align: PosAlign.left, bold: true));
        bytes += generator.text("TOTAL AMT  : PENDING");
      } else {
        bytes += generator.text("FAT        : ${fat.toStringAsFixed(1)} %");
        bytes += generator.text("SNF        : ${snf.toStringAsFixed(1)} %");
        bytes += generator.text("Rate       : Rs. ${rate.toStringAsFixed(2)} /L");
        bytes += generator.text("--------------------------------");
        bytes += generator.setStyles(const PosStyles(align: PosAlign.left, bold: true, height: PosTextSize.size1, width: PosTextSize.size1));
        bytes += generator.text("TOTAL AMT  : Rs. ${totalAmount.toStringAsFixed(2)}");
      }

      bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: false));
      bytes += generator.text("================================");
      bytes += generator.text("Thank You!");
      bytes += generator.feed(3);
      bytes += generator.cut();

      await PrintBluetoothThermal.writeBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Print 10-Day Summary Slip (ESC/POS 58mm format)
  Future<bool> printTenDaySummarySlip({
    required String dairyName,
    required String dairyCode,
    required String farmerId,
    required String farmerName,
    required String periodStr,
    required List<dynamic> cycleCollections,
    required double totalLiters,
    required double avgFat,
    required double avgSnf,
    required double totalAmount,
  }) async {
    final connected = await isConnected();
    if (!connected) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Header
      bytes += generator.reset();
      bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text(dairyName.replaceAll(RegExp(r'\([^\)]*\)'), '').trim());
      bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: false, height: PosTextSize.size1, width: PosTextSize.size1));
      bytes += generator.text("CODE: $dairyCode");
      bytes += generator.text("================================");
      bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text("10-DAY SUMMARY ($periodStr)");
      bytes += generator.setStyles(const PosStyles(align: PosAlign.left, bold: false));
      bytes += generator.text("--------------------------------");
      bytes += generator.text("Farmer ID  : $farmerId");
      bytes += generator.text("Name       : $farmerName");
      bytes += generator.text("--------------------------------");

      // Table Headers
      bytes += generator.text("Date  Shft   Qty    Amt");
      bytes += generator.text("--------------------------------");
      for (var c in cycleCollections) {
        final dStr = "${c.date.day.toString().padLeft(2, '0')}/${c.date.month.toString().padLeft(2, '0')}";
        final sStr = c.session.toString().split('.').last == 'morning' ? "AM" : "PM";
        final qStr = c.liters.toStringAsFixed(1);
        final aStr = c.isPendingFat ? "-" : c.totalAmount.toStringAsFixed(0);
        
        final row = "${dStr.padRight(6)}${sStr.padRight(6)}${qStr.padRight(7)}Rs.$aStr";
        bytes += generator.text(row);
      }
      bytes += generator.text("--------------------------------");
      bytes += generator.text("Total Qty  : ${totalLiters.toStringAsFixed(1)} L");
      bytes += generator.text("Avg FAT    : ${avgFat.toStringAsFixed(1)} %");
      bytes += generator.text("Avg SNF    : ${avgSnf.toStringAsFixed(1)} %");
      bytes += generator.setStyles(const PosStyles(align: PosAlign.left, bold: true));
      bytes += generator.text("TOTAL AMT  : Rs. ${totalAmount.toStringAsFixed(2)}");

      bytes += generator.text("================================");
      bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: false));
      bytes += generator.text("Thank You!");
      bytes += generator.feed(3);
      bytes += generator.cut();

      await PrintBluetoothThermal.writeBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Print Payout Slip (ESC/POS 58mm format)
  Future<bool> printPaymentSlip({
    required String dairyName,
    required String dairyCode,
    required String farmerId,
    required String farmerName,
    required DateTime date,
    required double amount,
    required String paymentType,
    required String notes,
  }) async {
    final connected = await isConnected();
    if (!connected) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Header
      bytes += generator.reset();
      bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text(dairyName.replaceAll(RegExp(r'\([^\)]*\)'), '').trim());
      bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: false, height: PosTextSize.size1, width: PosTextSize.size1));
      bytes += generator.text("CODE: $dairyCode");
      bytes += generator.text("================================");

      // Label
      bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text("PAYOUT RECEIPT");
      bytes += generator.setStyles(const PosStyles(align: PosAlign.left, bold: false));
      bytes += generator.text("--------------------------------");

      // Details
      final dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      bytes += generator.text("Date: $dateStr    Time: $timeStr");
      bytes += generator.text("Farmer ID  : $farmerId");
      bytes += generator.text("Name       : $farmerName");
      bytes += generator.text("--------------------------------");
      
      bytes += generator.setStyles(const PosStyles(align: PosAlign.left, bold: true));
      bytes += generator.text("Amount Paid: Rs. ${amount.toStringAsFixed(2)}");
      bytes += generator.setStyles(const PosStyles(align: PosAlign.left, bold: false));
      
      bytes += generator.text("Paid Via   : $paymentType");
      if (notes.isNotEmpty) {
        bytes += generator.text("Notes      : $notes");
      }

      bytes += generator.text("================================");
      bytes += generator.setStyles(const PosStyles(align: PosAlign.center, bold: false));
      bytes += generator.text("Thank You!");
      bytes += generator.feed(3);
      bytes += generator.cut();

      await PrintBluetoothThermal.writeBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }
}
