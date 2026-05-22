from django.urls import path

from .views import (ClassificationView, EntityExtractionView,
                    LanguageDetectionView, NLPHistoryView,
                    SentimentAnalysisView, SummarizationView, TranslationView)

urlpatterns = [
    path("sentiment/", SentimentAnalysisView.as_view(), name="sentiment"),
    path("entities/", EntityExtractionView.as_view(), name="entities"),
    path("detect-language/", LanguageDetectionView.as_view(), name="detect-language"),
    path("translate/", TranslationView.as_view(), name="translate"),
    path("summarize/", SummarizationView.as_view(), name="summarize"),
    path("classify/", ClassificationView.as_view(), name="classify"),
    path("history/", NLPHistoryView.as_view(), name="nlp-history"),
]
