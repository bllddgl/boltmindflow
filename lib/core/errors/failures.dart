/// Failure types surfaced to the presentation layer.
///
/// Domain throws typed exceptions; data-layer repositories catch and map them
/// to [Failure]. The UI therefore has a single error vocabulary to render.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class OfflineFailure extends Failure {
  const OfflineFailure([super.message = 'This feature needs a network connection.']);
}

class PremiumRequiredFailure extends Failure {
  const PremiumRequiredFailure([super.message = 'This feature requires MindFlow Premium.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found.']);
}

class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Could not parse this document.']);
}

class UnsupportedFormatFailure extends Failure {
  const UnsupportedFormatFailure([super.message = 'This file format is not supported.']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Could not access local storage.']);
}

class AiFailure extends Failure {
  const AiFailure([super.message = 'The AI service is unavailable right now.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
