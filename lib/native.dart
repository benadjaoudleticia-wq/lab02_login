import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    // Dossier réservé à l'application (plus fiable que Documents)
    final dbFolder = await getApplicationSupportDirectory();
    // On s'assure que le dossier existe vraiment
    await Directory(dbFolder.path).create(recursive: true);
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    print('DB FILE: ${file.path}');
    return NativeDatabase(file);
  });
}