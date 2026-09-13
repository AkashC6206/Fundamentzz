abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database operation failed']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

class InsufficientStockFailure extends Failure {
  const InsufficientStockFailure([super.message = 'Insufficient stock available']);
}

class BackupRestoreFailure extends Failure {
  const BackupRestoreFailure(super.message);
}
