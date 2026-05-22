from django.urls import path

from .views import (AnalysisHistoryView, FaceDetectionView, ImageLabelingView,
                    ObjectDetectionView, OCRView)

urlpatterns = [
    path("ocr/", OCRView.as_view(), name="ocr"),
    path("detect-objects/", ObjectDetectionView.as_view(), name="detect-objects"),
    path("detect-faces/", FaceDetectionView.as_view(), name="detect-faces"),
    path("label-image/", ImageLabelingView.as_view(), name="label-image"),
    path("history/", AnalysisHistoryView.as_view(), name="analysis-history"),
]
