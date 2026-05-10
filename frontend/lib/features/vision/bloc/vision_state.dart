part of 'vision_bloc.dart';

enum VisionStatus { initial, loading, success, failure }

class VisionState extends Equatable {
  final VisionStatus status;
  final Map<String, dynamic>? result;
  final String? error;
  final String? currentOperation;

  const VisionState({
    this.status = VisionStatus.initial,
    this.result,
    this.error,
    this.currentOperation,
  });

  VisionState copyWith({
    VisionStatus? status,
    Map<String, dynamic>? result,
    String? error,
    String? currentOperation,
  }) {
    return VisionState(
      status: status ?? this.status,
      result: result ?? this.result,
      error: error,
      currentOperation: currentOperation ?? this.currentOperation,
    );
  }

  @override
  List<Object?> get props => [status, result, error, currentOperation];
}
