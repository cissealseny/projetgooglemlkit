from rest_framework import serializers
from .models import TextAnalysis


PROVIDER_CHOICES = ['auto', 'google', 'huggingface']


class TextAnalysisSerializer(serializers.ModelSerializer):
    """Serializer for TextAnalysis model"""
    
    class Meta:
        model = TextAnalysis
        fields = ['id', 'input_text', 'analysis_type', 'result', 
                  'processing_time', 'created_at']
        read_only_fields = ['id', 'result', 'processing_time', 'created_at']


class SentimentRequestSerializer(serializers.Serializer):
    """Serializer for sentiment analysis request"""
    
    text = serializers.CharField(max_length=10000)
    provider = serializers.ChoiceField(choices=PROVIDER_CHOICES, default='auto')


class EntityExtractionRequestSerializer(serializers.Serializer):
    """Serializer for entity extraction request"""
    
    text = serializers.CharField(max_length=10000)
    provider = serializers.ChoiceField(choices=PROVIDER_CHOICES, default='auto')
    

class LanguageDetectionRequestSerializer(serializers.Serializer):
    """Serializer for language detection request"""
    
    text = serializers.CharField(max_length=5000)


class TranslationRequestSerializer(serializers.Serializer):
    """Serializer for translation request"""
    
    text = serializers.CharField(max_length=10000)
    source_language = serializers.CharField(max_length=10, default='auto')
    target_language = serializers.CharField(max_length=10, default='en')
    provider = serializers.ChoiceField(choices=PROVIDER_CHOICES, default='auto')


class SummarizationRequestSerializer(serializers.Serializer):
    """Serializer for text summarization request"""
    
    text = serializers.CharField(max_length=50000)
    max_length = serializers.IntegerField(default=150, min_value=50, max_value=500)
    min_length = serializers.IntegerField(default=50, min_value=20, max_value=200)
    provider = serializers.ChoiceField(choices=PROVIDER_CHOICES, default='auto')


class ClassificationRequestSerializer(serializers.Serializer):
    """Serializer for text classification request"""
    
    text = serializers.CharField(max_length=10000)
    categories = serializers.ListField(
        child=serializers.CharField(max_length=100),
        required=False,
        default=list
    )
    provider = serializers.ChoiceField(choices=PROVIDER_CHOICES, default='auto')
