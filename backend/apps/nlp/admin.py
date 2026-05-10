from django.contrib import admin
from .models import TextAnalysis


@admin.register(TextAnalysis)
class TextAnalysisAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'analysis_type', 'processing_time', 'created_at']
    list_filter = ['analysis_type', 'created_at']
    search_fields = ['user__email', 'input_text']
    readonly_fields = ['result', 'processing_time', 'created_at']
