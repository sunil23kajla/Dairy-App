import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dairy_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Add logic here when incrementing version in the future 
    // Example: if (oldVersion < 2) { await db.execute('ALTER TABLE...'); }
    // This prevents existing data from being wiped out.
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNull = 'TEXT';
    const boolType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const realNull = 'REAL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE farmers (
  id TEXT NOT NULL,
  dairyCode $textType,
  name $textType,
  mobile $textNull,
  is_synced $boolType DEFAULT 0,
  updated_at $textType,
  PRIMARY KEY (id, dairyCode)
)
''');

    await db.execute('''
CREATE TABLE collections (
  localId $idType,
  dairyCode $textType,
  farmerId $textType,
  farmerName $textNull,
  date $textType,
  session $textType,
  liters $realType,
  fat $realNull,
  snf $realNull,
  rate $realType,
  totalAmount $realType,
  isPendingFat $boolType DEFAULT 0,
  is_synced $boolType DEFAULT 0,
  updated_at $textType
)
''');

    await db.execute('''
CREATE TABLE payouts (
  localId $idType,
  dairyCode $textType,
  farmerId $textType,
  farmerName $textNull,
  amount $realType,
  date $textType,
  paymentType $textType,
  notes $textNull,
  is_synced $boolType DEFAULT 0,
  updated_at $textType
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // Generic Operations
  Future<void> insertOrUpdate(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedRows(String table) async {
    final db = await instance.database;
    return await db.query(table, where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> markAsSynced(String table, String idColumn, String idValue) async {
    final db = await instance.database;
    await db.update(table, {'is_synced': 1}, where: '\$idColumn = ?', whereArgs: [idValue]);
  }
}
