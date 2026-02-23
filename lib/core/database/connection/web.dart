import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// 웹 환경 DB 연결 (IndexedDB 기반)
QueryExecutor openConnection() {
  return WebDatabase('nae_mo_db');
}
