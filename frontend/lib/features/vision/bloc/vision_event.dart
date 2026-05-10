part of 'vision_bloc.dart';

abstract class VisionEvent extends Equatable {
  const VisionEvent();

  @override
  List<Object?> get props => [];
}

class PerformOCR extends VisionEvent {
  final String imagePath;
  final bool useLocal;

  const PerformOCR({required this.imagePath, this.useLocal = true});

  @override
  List<Object> get props => [imagePath, useLocal];
}

class DetectFaces extends VisionEvent {
  final String imagePath;
  final bool useLocal;

  const DetectFaces({required this.imagePath, this.useLocal = true});

  @override
  List<Object> get props => [imagePath, useLocal];
}

class DetectObjects extends VisionEvent {
  final String imagePath;
  final bool useLocal;

  const DetectObjects({required this.imagePath, this.useLocal = true});

  @override
  List<Object> get props => [imagePath, useLocal];
}

class LabelImage extends VisionEvent {
  final String imagePath;
  final bool useLocal;

  const LabelImage({required this.imagePath, this.useLocal = true});

  @override
  List<Object> get props => [imagePath, useLocal];
}

class ScanBarcodes extends VisionEvent {
  final String imagePath;

  const ScanBarcodes({required this.imagePath});

  @override
  List<Object> get props => [imagePath];
}

class ClearVisionResult extends VisionEvent {}
