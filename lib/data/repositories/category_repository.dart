import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/category_model.dart';

class CategoryRepository {
  CategoryRepository(this._database);

  final AppDatabase _database;

  Stream<List<CategoryModel>> watchCategories() {
    return (_database.select(_database.categories)
          ..orderBy([(category) => OrderingTerm(expression: category.name)]))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }

  Future<CategoryModel?> findById(String categoryId) async {
    final row = await (_database.select(_database.categories)
          ..where((category) => category.id.equals(categoryId)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<void> save(CategoryModel category) {
    // An upsert, not insertOrReplace: REPLACE deletes the row first, which
    // would clear the categoryId of every alarm in the category.
    return _database.into(_database.categories).insertOnConflictUpdate(
          CategoriesCompanion.insert(
            id: category.id,
            name: category.name,
            emoji: category.emoji,
            createdAt: category.createdAt,
            updatedAt: category.updatedAt,
          ),
        );
  }

  Future<void> delete(String categoryId) {
    return _database.transaction(() async {
      await (_database.update(_database.alarms)
            ..where((alarm) => alarm.categoryId.equals(categoryId)))
          .write(const AlarmsCompanion(categoryId: Value(null)));
      await (_database.delete(_database.categories)
            ..where((category) => category.id.equals(categoryId)))
          .go();
    });
  }

  CategoryModel _toModel(Category row) {
    return CategoryModel(
      id: row.id,
      name: row.name,
      emoji: row.emoji,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
