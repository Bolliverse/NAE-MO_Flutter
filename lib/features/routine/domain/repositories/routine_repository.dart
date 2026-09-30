import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_definition.dart';

abstract interface class RoutineRepository {
  Future<Result<List<RoutineDefinition>>> getAll();
  Future<Result<RoutineDefinition>> create(RoutineDefinition routine);
}
