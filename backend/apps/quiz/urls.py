from django.urls import path

from .views import (
    QuizAttemptLatestView,
    QuizDetailView,
    QuizGenerateView,
    QuizGradeView,
    QuizListView,
)

urlpatterns = [
    path("generate/", QuizGenerateView.as_view(), name="quiz-generate"),
    path("history/", QuizListView.as_view(), name="quiz-history"),
    path("<int:pk>/", QuizDetailView.as_view(), name="quiz-detail"),
    path("grade/", QuizGradeView.as_view(), name="quiz-grade"),
    path(
        "attempts/latest/", QuizAttemptLatestView.as_view(), name="quiz-attempt-latest"
    ),
]
