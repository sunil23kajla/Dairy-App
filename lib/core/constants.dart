import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

enum Language { english, hindi }

enum Session { morning, evening }

class AppConstants {

  static Session getCurrentSession() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return Session.morning;
    } else {
      return Session.evening;
    }
  }


  static double calculateRate(double fat, double snf, {double fatFactor = 9.0, double baseSnf = 9.0}) {
    if (fat <= 0 || snf <= 0) return 0.0;
    final baseRate = fat * fatFactor;
    
    // SNF points deduction calculation
    final baseSnfPoints = (baseSnf * 10).round();
    final snfPoints = (snf * 10).round();
    final diff = baseSnfPoints - snfPoints;
    
    double deduction = 0.0;
    if (diff > 0) {
      if (diff <= 2) {
        deduction = diff * 0.10;
      } else {
        deduction = 0.20 + (diff - 2) * 0.20;
      }
    }
    
    final finalRate = baseRate - deduction;
    return double.parse((finalRate < 0.0 ? 0.0 : finalRate).toStringAsFixed(2));
  }

  // Translation Strings
  static const Map<String, Map<Language, String>> strings = {
    'appName': {
      Language.english: 'Smart Dairy Collection',
      Language.hindi: 'स्मार्ट डेयरी कलेक्शन',
    },
    'ownerLogin': {
      Language.english: 'Owner Login',
      Language.hindi: 'डेयरी मालिक लॉगिन',
    },
    'workerLogin': {
      Language.english: 'Worker Login',
      Language.hindi: 'डेयरी वर्कर लॉगिन',
    },
    'registerDairy': {
      Language.english: 'Register New Dairy',
      Language.hindi: 'नई डेयरी रजिस्टर करें',
    },
    'dairyCode': {
      Language.english: 'Dairy Code',
      Language.hindi: 'डेयरी कोड',
    },
    'dairyName': {
      Language.english: 'Dairy Name',
      Language.hindi: 'डेयरी का नाम',
    },
    'password': {
      Language.english: 'Password',
      Language.hindi: 'पासवर्ड',
    },
    'loginBtn': {
      Language.english: 'Log In',
      Language.hindi: 'लॉगिन करें',
    },
    'registerBtn': {
      Language.english: 'Register & Log In',
      Language.hindi: 'रजिस्टर और लॉगिन करें',
    },
    'backToLogin': {
      Language.english: 'Back to Login',
      Language.hindi: 'लॉगिन पर वापस जाएं',
    },
    'invalidCredentials': {
      Language.english: 'Invalid Mobile or Password',
      Language.hindi: 'गलत मोबाइल या पासवर्ड',
    },
    'invalidDairyCode': {
      Language.english: 'Invalid Dairy Code',
      Language.hindi: 'गलत डेयरी कोड',
    },
    'dairyCodeExists': {
      Language.english: 'Dairy Code already registered',
      Language.hindi: 'यह डेयरी कोड पहले से ही दर्ज है',
    },
    'mobileExists': {
      Language.english: 'Mobile number already registered',
      Language.hindi: 'यह मोबाइल नंबर पहले से ही दर्ज है',
    },
    'pinTitle': {
      Language.english: 'Enter Passcode',
      Language.hindi: 'पासकोड दर्ज करें',
    },
    'pinSubtitle': {
      Language.english: 'Access Smart Dairy Operations',
      Language.hindi: 'स्मार्ट डेयरी उपयोग के लिए',
    },
    'workerRole': {
      Language.english: 'Worker (संग्रहक)',
      Language.hindi: 'वर्कर (Worker)',
    },
    'ownerRole': {
      Language.english: 'Owner (डेयरी मालिक)',
      Language.hindi: 'मालिक (Owner)',
    },
    'todaySummary': {
      Language.english: "Today's Summary",
      Language.hindi: 'आज का हिसाब',
    },
    'totalLiters': {
      Language.english: 'Total Liters',
      Language.hindi: 'कुल दूध (लीटर)',
    },
    'totalAmount': {
      Language.english: 'Total Amount',
      Language.hindi: 'कुल राशि',
    },
    'pendingFat': {
      Language.english: 'Pending FAT',
      Language.hindi: 'बाकी फैट (FAT)',
    },
    'pendingPayment': {
      Language.english: 'Pending Payment',
      Language.hindi: 'बाकी भुगतान',
    },
    'milkEntry': {
      Language.english: 'New Milk Entry',
      Language.hindi: 'दूध की एंट्री (+)',
    },
    'searchFarmer': {
      Language.english: 'Search Farmer by ID/Name/Mobile',
      Language.hindi: 'किसान का नाम/ID/मोबाइल नंबर खोजें',
    },
    'enterLiters': {
      Language.english: 'Liters (लीटर)',
      Language.hindi: 'लीटर (Liters)',
    },
    'suggestedLiters': {
      Language.english: 'Suggested:',
      Language.hindi: 'सुझाया गया (कल का):',
    },
    'saveNext': {
      Language.english: 'Save & Next Farmer',
      Language.hindi: 'सहेजें और अगला किसान',
    },
    'pendingFatEntries': {
      Language.english: 'Pending FAT List',
      Language.hindi: 'बाकी FAT सूची',
    },
    'addFat': {
      Language.english: 'Enter FAT & SNF',
      Language.hindi: 'FAT और SNF दर्ज करें',
    },
    'fat': {
      Language.english: 'FAT (फैट)',
      Language.hindi: 'FAT (फैट)',
    },
    'snf': {
      Language.english: 'SNF (एसएनएफ)',
      Language.hindi: 'SNF (एसएनएफ)',
    },
    'rate': {
      Language.english: 'Rate (दर)',
      Language.hindi: 'दर (Rate)',
    },
    'total': {
      Language.english: 'Total (कुल)',
      Language.hindi: 'कुल (Total)',
    },
    'printReceipt': {
      Language.english: 'Print Receipt',
      Language.hindi: 'रसीद निकालें',
    },
    'payments': {
      Language.english: 'Payments',
      Language.hindi: 'भुगतान (हिसाब)',
    },
    'farmers': {
      Language.english: 'Farmers List',
      Language.hindi: 'किसानों की सूची',
    },
    'addFarmer': {
      Language.english: 'Add Farmer',
      Language.hindi: 'नया किसान जोड़ें',
    },
    'reports': {
      Language.english: 'Reports',
      Language.hindi: 'रिपोर्ट',
    },
    'settings': {
      Language.english: 'Settings',
      Language.hindi: 'सेटिंग्स',
    },
    'language': {
      Language.english: 'Language',
      Language.hindi: 'भाषा (Language)',
    },
    'theme': {
      Language.english: 'App Theme',
      Language.hindi: 'थीम (Theme)',
    },
    'workerAccessOnly': {
      Language.english: 'Action Restricted for Workers',
      Language.hindi: 'यह कार्य केवल मालिक कर सकते हैं',
    },
    'duplicateWarning': {
      Language.english: 'Already recorded for this session today!',
      Language.hindi: 'आज इस सत्र के लिए पहले ही रिकॉर्ड किया जा चुका है!',
    },
    'paid': {
      Language.english: 'Paid (दिया)',
      Language.hindi: 'दिया (Paid)',
    },
    'pending': {
      Language.english: 'Pending (बाकी)',
      Language.hindi: 'बाकी (Pending)',
    },
    'nickname': {
      Language.english: 'Nickname',
      Language.hindi: 'उपनाम',
    },
    'mobile': {
      Language.english: 'Mobile Number',
      Language.hindi: 'मोबाइल नंबर',
    },
    'farmerName': {
      Language.english: 'Farmer Name',
      Language.hindi: 'किसान का नाम',
    },
    'id': {
      Language.english: 'ID/Number',
      Language.hindi: 'किसान क्रमांक (ID)',
    },
    'rateSettings': {
      Language.english: 'Rate Settings',
      Language.hindi: 'दर सेटिंग्स (Rate Settings)',
    },
    'rateFormulaHint': {
      Language.english: 'Rate calculation: (FAT * FAT Price) - SNF Deduction (10p for 8.9-8.8, 20p below 8.8)',
      Language.hindi: 'दर गणना: (FAT * प्रति फैट दर) - SNF कटौती (8.9-8.8 पर 10 पैसे, 8.8 से नीचे 20 पैसे)',
    },
    'fatMultiplier': {
      Language.english: 'FAT Price per Point (₹/FAT)',
      Language.hindi: 'प्रति फैट दर (₹/FAT)',
    },
    'snfMultiplier': {
      Language.english: 'Base SNF Target (e.g. 9.0)',
      Language.hindi: 'मानक SNF लक्ष्य (जैसे 9.0)',
    },
    'saveSettings': {
      Language.english: 'Save Settings',
      Language.hindi: 'सेटिंग्स सहेजें',
    },
    'cancel': {
      Language.english: 'Cancel',
      Language.hindi: 'रद्द करें',
    },
    'rateUpdatedSnackbar': {
      Language.english: 'Rate factors updated!',
      Language.hindi: 'दर मूल्य गुणांक अपडेट हो गए हैं!',
    },
    'receiptHeader': {
      Language.english: 'SMART DAIRY COOPERATIVE',
      Language.hindi: 'स्मार्ट डेयरी सहकारी समिति',
    },
    'receiptDivider': {
      Language.english: '---------------------------',
      Language.hindi: '---------------------------',
    },
    'receiptDate': {
      Language.english: 'Date',
      Language.hindi: 'दिनांक',
    },
    'receiptSession': {
      Language.english: 'Session',
      Language.hindi: 'सत्र',
    },
    'receiptFarmerId': {
      Language.english: 'Farmer ID',
      Language.hindi: 'किसान आईडी',
    },
    'receiptName': {
      Language.english: 'Name',
      Language.hindi: 'नाम',
    },
    'receiptMilkVol': {
      Language.english: 'Milk Vol',
      Language.hindi: 'दूध मात्रा',
    },
    'receiptFat': {
      Language.english: 'FAT %',
      Language.hindi: 'फैट %',
    },
    'receiptSnf': {
      Language.english: 'SNF %',
      Language.hindi: 'एसएनएफ %',
    },
    'receiptRate': {
      Language.english: 'Rate',
      Language.hindi: 'दर',
    },
    'receiptTotalAmt': {
      Language.english: 'TOTAL AMT',
      Language.hindi: 'कुल राशि',
    },
    'receiptThankYou': {
      Language.english: 'THANK YOU FOR YOUR TRUST',
      Language.hindi: 'आपके विश्वास के लिए धन्यवाद',
    },
    'printNow': {
      Language.english: 'Print Now',
      Language.hindi: 'प्रिंट करें',
    },
    'close': {
      Language.english: 'Close',
      Language.hindi: 'बंद करें',
    },
    'duplicateTitle': {
      Language.english: 'Duplicate Entry Warning',
      Language.hindi: 'डुप्लीकेट प्रविष्टि चेतावनी',
    },
    'duplicateBody': {
      Language.english: 'This farmer already has a recorded entry for today\'s session. Do you want to overwrite it?',
      Language.hindi: 'इस किसान की आज के इस सत्र के लिए प्रविष्टि पहले से ही दर्ज है। क्या आप इसे बदलना चाहते हैं?',
    },
    'overwrite': {
      Language.english: 'Overwrite',
      Language.hindi: 'बदलें (ओवरराइट)',
    },
    'recordPayoutTitle': {
      Language.english: 'Record Payout to',
      Language.hindi: 'भुगतान दर्ज करें - ',
    },
    'outstanding': {
      Language.english: 'Current Outstanding',
      Language.hindi: 'कुल बकाया राशि',
    },
    'amountLabel': {
      Language.english: 'Payment Amount (₹)',
      Language.hindi: 'भुगतान राशि (₹)',
    },
    'paymentTypeLabel': {
      Language.english: 'Payment Type',
      Language.hindi: 'भुगतान का प्रकार',
    },
    'notesLabel': {
      Language.english: 'Notes (Optional)',
      Language.hindi: 'टिप्पणी (वैकल्पिक)',
    },
    'cash': {
      Language.english: 'Cash',
      Language.hindi: 'नकद',
    },
    'bankTransfer': {
      Language.english: 'Bank Transfer',
      Language.hindi: 'बैंक ट्रांसफर',
    },
    'savePayment': {
      Language.english: 'Save Payment',
      Language.hindi: 'भुगतान सुरक्षित करें',
    },
    'tenDaySlip': {
      Language.english: '10-Day Slip',
      Language.hindi: '10 दिनों का हिसाब (Hafte ki list)',
    },
    'whatsappShare': {
      Language.english: 'WhatsApp Share',
      Language.hindi: 'व्हाट्सएप शेयर',
    },
    'shareSuccess': {
      Language.english: 'Opening WhatsApp to share slip...',
      Language.hindi: 'व्हाट्सएप पर पर्ची साझा की जा रही है...',
    },
    'dialSuccess': {
      Language.english: 'Opening phone dialer...',
      Language.hindi: 'फ़ोन डायलर खोला जा रहा है...',
    },
    'payoutLogged': {
      Language.english: 'Payment logged successfully!',
      Language.hindi: 'भुगतान सफलता पूर्वक दर्ज हो गया!',
    },
    'validAmountError': {
      Language.english: 'Please enter a valid amount',
      Language.hindi: 'कृपया एक वैध राशि दर्ज करें',
    },
    'morningStr': {
      Language.english: 'Morning',
      Language.hindi: 'सुबह',
    },
    'eveningStr': {
      Language.english: 'Evening',
      Language.hindi: 'शाम',
    },
    'quickOperations': {
      Language.english: 'Quick Operations',
      Language.hindi: 'त्वरित कार्य',
    },
    'dailyMonthlyReportsDesc': {
      Language.english: 'View Daily and Monthly reports',
      Language.hindi: 'दैनिक और मासिक रिपोर्ट देखें',
    },
    'milkEntryDesc': {
      Language.english: 'Fast collection entry',
      Language.hindi: 'संग्रह केंद्र पर तेजी से एंट्री',
    },
    'pendingFatDesc': {
      Language.english: 'Enter FAT & SNF from lab',
      Language.hindi: 'लैब से FAT और SNF दर्ज करें',
    },
    'paymentsDesc': {
      Language.english: 'Settle farmer ledger',
      Language.hindi: 'किसान का खाता हिसाब करें',
    },
    'farmersDesc': {
      Language.english: 'Manage farmer profiles',
      Language.hindi: 'किसानों की प्रोफ़ाइल प्रबंधित करें',
    },
    'noFarmersFound': {
      Language.english: 'No farmers found',
      Language.hindi: 'कोई किसान नहीं मिला',
    },
    'noPaymentsHistory': {
      Language.english: 'No payments recorded yet',
      Language.hindi: 'अभी तक कोई भुगतान दर्ज नहीं किया गया है',
    },
    'balanceLabel': {
      Language.english: 'Balance',
      Language.hindi: 'बकाया राशि',
    },
    'pay': {
      Language.english: 'Pay',
      Language.hindi: 'भुगतान करें',
    },
    'type': {
      Language.english: 'Type',
      Language.hindi: 'प्रकार',
    },
    'dailyReport': {
      Language.english: 'Daily Report',
      Language.hindi: 'दैनिक रिपोर्ट',
    },
    'farmerWise': {
      Language.english: 'Farmer Wise',
      Language.hindi: 'किसान अनुसार',
    },
    'todaysCollections': {
      Language.english: "Today's Collections",
      Language.hindi: 'आज का संग्रह',
    },
    'noCollectionsToday': {
      Language.english: 'No collections recorded today yet',
      Language.hindi: 'आज अभी तक कोई संग्रह दर्ज नहीं किया गया है',
    },
    'selectFarmerToViewLedger': {
      Language.english: 'Select Farmer to view ledger',
      Language.hindi: 'बहीखाता देखने के लिए किसान का चयन करें',
    },
    'chooseFarmer': {
      Language.english: 'Choose a Farmer',
      Language.hindi: 'किसान चुनें',
    },
    'pleaseSelectFarmerHint': {
      Language.english: 'Please select a farmer above to display stats',
      Language.hindi: 'आंकड़े देखने के लिए कृपया ऊपर एक किसान का चयन करें',
    },
    'ledgerSummaryFor': {
      Language.english: 'Ledger Summary for',
      Language.hindi: 'के लिए खाता सारांश',
    },
    'totalMilkDelivered': {
      Language.english: 'Total Milk Delivered',
      Language.hindi: 'कुल वितरित दूध',
    },
    'averageFatValue': {
      Language.english: 'Average FAT Value',
      Language.hindi: 'औसत फैट मान',
    },
    'totalMoneyEarned': {
      Language.english: 'Total Money Earned',
      Language.hindi: 'कुल अर्जित राशि',
    },
    'totalPaymentsReceived': {
      Language.english: 'Total Payments Received',
      Language.hindi: 'कुल प्राप्त भुगतान',
    },
    'outstandingBalance': {
      Language.english: 'Outstanding Balance',
      Language.hindi: 'शेष बकाया राशि',
    },
    'noLogsFound': {
      Language.english: 'No transaction logs found for this farmer',
      Language.hindi: 'इस किसान के लिए कोई लेनदेन लॉग नहीं मिला',
    },
    'milkLogMorning': {
      Language.english: 'Milk Log (AM)',
      Language.hindi: 'दूध संग्रह (सुबह)',
    },
    'milkLogEvening': {
      Language.english: 'Milk Log (PM)',
      Language.hindi: 'दूध संग्रह (शाम)',
    },
    'payout': {
      Language.english: 'Payout',
      Language.hindi: 'भुगतान',
    },
    'allFatEntriesCompleted': {
      Language.english: 'All FAT entries completed!',
      Language.hindi: 'सभी फैट प्रविष्टियां पूर्ण हो गईं!',
    },
    'noPendingEntriesFound': {
      Language.english: 'No pending entries found for today',
      Language.hindi: 'आज के लिए कोई लंबित प्रविष्टि नहीं मिली',
    },
    'enterFatBtn': {
      Language.english: 'Enter FAT',
      Language.hindi: 'फैट दर्ज करें',
    },
    'editFarmer': {
      Language.english: 'Edit Farmer',
      Language.hindi: 'किसान प्रोफ़ाइल संपादित करें',
    },
    'pleaseEnterName': {
      Language.english: 'Please enter name',
      Language.hindi: 'कृपया नाम दर्ज करें',
    },
    'pleaseEnterMobile': {
      Language.english: 'Please enter mobile number',
      Language.hindi: 'कृपया मोबाइल नंबर दर्ज करें',
    },
    'pleaseEnterValidMobile': {
      Language.english: 'Please enter a valid 10-digit number',
      Language.hindi: 'कृपया एक वैध 10-अंकीय नंबर दर्ज करें',
    },
    'updateDetails': {
      Language.english: 'Update Details',
      Language.hindi: 'विवरण अपडेट करें',
    },
    'saveFarmer': {
      Language.english: 'Save Farmer',
      Language.hindi: 'किसान सुरक्षित करें',
    },
    'farmerAddedSuccess': {
      Language.english: 'Farmer Added successfully!',
      Language.hindi: 'किसान सफलतापूर्वक जोड़ा गया!',
    },
    'farmerUpdatedSuccess': {
      Language.english: 'Farmer updated successfully!',
      Language.hindi: 'किसान की जानकारी अपडेट की गई!',
    },
    'typeFarmerToBegin': {
      Language.english: 'Type Farmer ID or Name to begin',
      Language.hindi: 'खोजने के लिए किसान आईडी या नाम लिखें',
    },
    'load': {
      Language.english: 'Load',
      Language.hindi: 'भरे',
    },
    'liters': {
      Language.english: 'Liters',
      Language.hindi: 'लीटर',
    },
    'validLitersError': {
      Language.english: 'Please enter a valid liter amount',
      Language.hindi: 'कृपया एक वैध लीटर मात्रा दर्ज करें',
    },
    'savedSuccess': {
      Language.english: 'Saved!',
      Language.hindi: 'सहेज लिया गया!',
    },
    'thermalSlipPreview': {
      Language.english: 'Thermal Slip Preview',
      Language.hindi: 'थर्मल रसीद पूर्वावलोकन',
    },
    'printingReceipt': {
      Language.english: 'Printing receipt on Bluetooth Thermal Printer...',
      Language.hindi: 'ब्लूटूथ थर्मल प्रिंटर पर रसीद प्रिंट की जा रही है...',
    },
    'validationError': {
      Language.english: 'Please enter valid FAT and SNF values',
      Language.hindi: 'कृपया वैध FAT और SNF मान दर्ज करें',
    },
    'invalidPin': {
      Language.english: 'Invalid PIN (Worker: 1111, Owner: 2222)',
      Language.hindi: 'गलत पिन (वर्कर: 1111, मालिक: 2222)',
    },
    'clear': {
      Language.english: 'Clear',
      Language.hindi: 'साफ़ करें',
    },
    'generateTenDaySlip': {
      Language.english: 'Generate 10-Day Slip',
      Language.hindi: '10-दिवसीय पर्ची बनाएं',
    },
    'cyclePeriodLabel': {
      Language.english: 'Select Cycle Period',
      Language.hindi: 'चक्र अवधि चुनें',
    },
    'cycle1': {
      Language.english: '1st to 10th of Month',
      Language.hindi: 'तारीख 1 से 10',
    },
    'cycle2': {
      Language.english: '11th to 20th of Month',
      Language.hindi: 'तारीख 11 से 20',
    },
    'cycle3': {
      Language.english: '21st to End of Month',
      Language.hindi: 'तारीख 21 से अंत',
    },
    'avgSnfValue': {
      Language.english: 'Average SNF Value',
      Language.hindi: 'औसत एसएनएफ मान',
    },
    'date': {
      Language.english: 'Date',
      Language.hindi: 'दिनांक',
    },
    'session': {
      Language.english: 'Session',
      Language.hindi: 'सत्र',
    },
    'ratePerLiter': {
      Language.english: 'Rate/L',
      Language.hindi: 'दर/लीटर',
    },
    'amount': {
      Language.english: 'Amount',
      Language.hindi: 'राशि',
    },
    'nicknameHint': {
      Language.english: 'Enter Nickname (Optional)',
      Language.hindi: 'उपनाम दर्ज करें (वैकल्पिक)',
    },
    'nameHint': {
      Language.english: 'Enter Farmer Name',
      Language.hindi: 'किसान का नाम दर्ज करें',
    },
    'mobileHint': {
      Language.english: 'Enter 10-digit Mobile Number',
      Language.hindi: '10-अंकीय मोबाइल नंबर दर्ज करें',
    },
    'englishName': {
      Language.english: 'English',
      Language.hindi: 'अंग्रेजी',
    },
    'hindiName': {
      Language.english: 'Hindi',
      Language.hindi: 'हिन्दी',
    },
    'farmerLedger': {
      Language.english: 'Farmer Ledger',
      Language.hindi: 'किसान खाता',
    },
    'paymentHistory': {
      Language.english: 'Payment History',
      Language.hindi: 'भुगतान इतिहास',
    },
    'logoutTitle': {
      Language.english: 'Confirm Logout',
      Language.hindi: 'लॉगआउट की पुष्टि करें',
    },
    'logoutBody': {
      Language.english: 'Are you sure you want to logout?',
      Language.hindi: 'क्या आप वाकई लॉगआउट करना चाहते हैं?',
    },
    'logoutBtn': {
      Language.english: 'Logout',
      Language.hindi: 'लॉगआउट करें',
    },
    'saveSuccessPrintLater': {
      Language.english: 'Saved successfully! Print slip later from history.',
      Language.hindi: 'सफलतापूर्वक सुरक्षित किया गया! रसीद इतिहास से बाद में निकालें।',
    },
    'saveFatBtn': {
      Language.english: 'Save FAT/SNF',
      Language.hindi: 'फैट/SNF सुरक्षित करें',
    },
    'addTo': {
      Language.english: 'Add To',
      Language.hindi: 'जोड़ें (Add To)',
    },
    'editedBadge': {
      Language.english: 'Edited',
      Language.hindi: 'संशोधित',
    },
    'previousValue': {
      Language.english: 'Previous Value',
      Language.hindi: 'पिछला मूल्य',
    },
  };

  // Helper to translate strings
  static String translate(String key, Language lang) {
    if (strings.containsKey(key) && strings[key]!.containsKey(lang)) {
      return strings[key]![lang]!;
    }
    return key;
  }

  // API Base URL - Change this when deploying to Render or using ngrok
  static const String baseUrl = 'http://192.168.1.8:5000/api';

  static Future<void> shareToWhatsApp({
    required String mobile,
    required String message,
  }) async {
    var phone = mobile.replaceAll(RegExp(r'\s+|-'), '');
    if (!phone.startsWith('+')) {
      if (phone.length == 10) {
        phone = '+91$phone';
      }
    }
    final Uri whatsappScheme = Uri.parse('whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}');
    final Uri webUrl = Uri.parse('https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}');
    
    try {
      if (await canLaunchUrl(whatsappScheme)) {
        await launchUrl(whatsappScheme);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }
}
