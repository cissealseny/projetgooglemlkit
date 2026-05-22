from django.conf import settings
from django.db import models


class TextAnalysis(models.Model):
    """Model to store NLP analysis results"""

    ANALYSIS_TYPES = [
        ("sentiment", "Sentiment Analysis"),
        ("entities", "Entity Extraction"),
        ("language", "Language Detection"),
        ("translation", "Translation"),
        ("summarization", "Text Summarization"),
        ("classification", "Text Classification"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="text_analyses"
    )
    input_text = models.TextField()
    analysis_type = models.CharField(max_length=20, choices=ANALYSIS_TYPES)
    result = models.JSONField(default=dict)
    processing_time = models.FloatField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "text_analyses"
        verbose_name = "Text Analysis"
        verbose_name_plural = "Text Analyses"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.analysis_type} - {self.user.email} - {self.created_at}"
