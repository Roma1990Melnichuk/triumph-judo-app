import 'dart:async';

extension SafeStreamX<T> on Stream<T> {
  /// Emits [fallback] instead of propagating errors — prevents StreamProviders
  /// from staying in AsyncLoading forever when a Firestore stream fails and
  /// closes (e.g. missing composite index or permission denied).
  Stream<T> fallbackOnError(T fallback) => transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (_, __, sink) => sink.add(fallback),
        ),
      );
}
