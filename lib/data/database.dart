import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:iwak_peyek/data/categories.dart';
import 'package:iwak_peyek/data/transaction.dart';

part 'database.g.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

@DriftDatabase(tables: [TodoItems, Categories, Transactions])
class AppDatabase extends _$AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();

  AppDatabase._internal([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  factory AppDatabase() {
    return _instance;
  }

  @override
  int get schemaVersion => 1;

  Future<List<Category>> getAllCategoriesRepo(int type) async {
    return await (select(
      categories,
    )..where((tbl) => tbl.type.equals(type))).get();
  }

  Future<List<TransactionData>> getAllTransactions() async {
    return await select(transactions).get();
  }

  Future<bool> deleteTransaction(int id) async {
    return await (delete(transactions)..where((tbl) => tbl.id.equals(id)))
        .go()
        .then((_) => true)
        .catchError((_) => false);
  }

  Future<bool> updateTransaction(TransactionData transaction) async {
    return await update(
      transactions,
    ).replace(transaction).then((_) => true).catchError((_) => false);
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'iwak_peyek.db'));
      return NativeDatabase(file);
    });
  }
}
