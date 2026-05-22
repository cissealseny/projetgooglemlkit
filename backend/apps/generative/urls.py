from django.urls import path

from .views import (
    ChatView,
    CodeGenerationView,
    ConversationDetailView,
    ConversationListView,
    EmbeddingView,
    GenerationHistoryView,
    TextGenerationView,
)

urlpatterns = [
    path("chat/", ChatView.as_view(), name="chat"),
    path("conversations/", ConversationListView.as_view(), name="conversations"),
    path(
        "conversations/<int:pk>/",
        ConversationDetailView.as_view(),
        name="conversation-detail",
    ),
    path("generate-text/", TextGenerationView.as_view(), name="generate-text"),
    path("generate-code/", CodeGenerationView.as_view(), name="generate-code"),
    path("embedding/", EmbeddingView.as_view(), name="embedding"),
    path("history/", GenerationHistoryView.as_view(), name="generation-history"),
]
