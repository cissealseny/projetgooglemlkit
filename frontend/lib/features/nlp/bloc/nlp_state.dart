part of 'nlp_bloc.dart';

enum NLPStatus { initial, loading, success, failure }

class NLPState extends Equatable {
  final NLPStatus status;
  final Map<String, dynamic>? result;
  final String? error;
  final String? currentOperation;

  const NLPState({
    this.status = NLPStatus.initial,
    this.result,
    this.error,
    this.currentOperation,
  });

  NLPState copyWith({
    NLPStatus? status,
    Map<String, dynamic>? result,
    String? error,
    String? currentOperation,
  }) {
    return NLPState(
      status: status ?? this.status,
      result: result ?? this.result,
      error: error,
      currentOperation: currentOperation ?? this.currentOperation,
    );
  }

  @override
  List<Object?> get props => [status, result, error, currentOperation];
}
