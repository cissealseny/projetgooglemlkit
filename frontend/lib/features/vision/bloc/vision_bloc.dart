import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../repository/vision_repository.dart';

part 'vision_event.dart';
part 'vision_state.dart';

class VisionBloc extends Bloc<VisionEvent, VisionState> {
  final VisionRepository _repository;

  VisionBloc(this._repository) : super(const VisionState()) {
    on<PerformOCR>(_onPerformOCR);
    on<DetectFaces>(_onDetectFaces);
    on<DetectObjects>(_onDetectObjects);
    on<LabelImage>(_onLabelImage);
    on<ScanBarcodes>(_onScanBarcodes);
    on<ClearVisionResult>(_onClearResult);
  }

  Future<void> _onPerformOCR(
    PerformOCR event,
    Emitter<VisionState> emit,
  ) async {
    emit(state.copyWith(status: VisionStatus.loading, currentOperation: 'OCR'));

    try {
      final result = event.useLocal
          ? await _repository.performLocalOCR(event.imagePath)
          : await _repository.performRemoteOCR(File(event.imagePath));

      if (result['success'] == true) {
        emit(state.copyWith(status: VisionStatus.success, result: result));
      } else {
        emit(
          state.copyWith(
            status: VisionStatus.failure,
            error: result['error'] ?? 'OCR failed',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: VisionStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onDetectFaces(
    DetectFaces event,
    Emitter<VisionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: VisionStatus.loading,
        currentOperation: 'Face Detection',
      ),
    );

    try {
      final result = event.useLocal
          ? await _repository.detectFacesLocal(event.imagePath)
          : await _repository.detectFacesRemote(File(event.imagePath));

      if (result['success'] == true) {
        emit(state.copyWith(status: VisionStatus.success, result: result));
      } else {
        emit(
          state.copyWith(
            status: VisionStatus.failure,
            error: result['error'] ?? 'Face detection failed',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: VisionStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onDetectObjects(
    DetectObjects event,
    Emitter<VisionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: VisionStatus.loading,
        currentOperation: 'Object Detection',
      ),
    );

    try {
      final result = event.useLocal
          ? await _repository.detectObjectsLocal(event.imagePath)
          : await _repository.detectObjectsRemote(File(event.imagePath));

      if (result['success'] == true) {
        emit(state.copyWith(status: VisionStatus.success, result: result));
      } else {
        emit(
          state.copyWith(
            status: VisionStatus.failure,
            error: result['error'] ?? 'Object detection failed',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: VisionStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onLabelImage(
    LabelImage event,
    Emitter<VisionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: VisionStatus.loading,
        currentOperation: 'Image Labeling',
      ),
    );

    try {
      final result = event.useLocal
          ? await _repository.labelImageLocal(event.imagePath)
          : await _repository.labelImageRemote(File(event.imagePath));

      if (result['success'] == true) {
        emit(state.copyWith(status: VisionStatus.success, result: result));
      } else {
        emit(
          state.copyWith(
            status: VisionStatus.failure,
            error: result['error'] ?? 'Image labeling failed',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: VisionStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onScanBarcodes(
    ScanBarcodes event,
    Emitter<VisionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: VisionStatus.loading,
        currentOperation: 'Barcode Scanning',
      ),
    );

    try {
      final result = await _repository.scanBarcodes(event.imagePath);

      if (result['success'] == true) {
        emit(state.copyWith(status: VisionStatus.success, result: result));
      } else {
        emit(
          state.copyWith(
            status: VisionStatus.failure,
            error: result['error'] ?? 'Barcode scanning failed',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: VisionStatus.failure, error: e.toString()));
    }
  }

  void _onClearResult(ClearVisionResult event, Emitter<VisionState> emit) {
    emit(const VisionState());
  }
}
