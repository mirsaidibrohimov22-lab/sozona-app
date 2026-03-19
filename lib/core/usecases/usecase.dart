// lib/core/usecases/usecase.dart
// So'zona — UseCase bazaviy klassi
// Barcha use case'lar bu interfeysni implement qiladi

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:my_first_app/core/error/failures.dart';

/// UseCase bazaviy interfeysi
/// [Result] — muvaffaqiyatli natija turi
/// [Params] — parametrlar turi
abstract class UseCase<Result, Params> {
  /// Use case'ni ishga tushirish
  Future<Either<Failure, Result>> call(Params params);
}

/// Parametrsiz use case uchun
/// Masalan: SignOut, GetCurrentUser
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object> get props => [];
}
