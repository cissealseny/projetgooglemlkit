from rest_framework import status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils import timezone

from .models import TextAnalysis
from .serializers import (
    TextAnalysisSerializer,
    SentimentRequestSerializer,
    EntityExtractionRequestSerializer,
    LanguageDetectionRequestSerializer,
    TranslationRequestSerializer,
    SummarizationRequestSerializer,
    ClassificationRequestSerializer
)
from .services import nlp_service


class SentimentAnalysisView(APIView):
    """Sentiment Analysis endpoint"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = SentimentRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        text = serializer.validated_data['text']
        provider = serializer.validated_data.get('provider', 'auto')
        result = nlp_service.analyze_sentiment(text, provider=provider)
        
        # Save analysis
        analysis = TextAnalysis.objects.create(
            user=request.user,
            input_text=text,
            analysis_type='sentiment',
            result=result,
            processing_time=result.get('processing_time')
        )
        
        # Update user API usage
        request.user.api_calls_count += 1
        request.user.last_api_call = timezone.now()
        request.user.save(update_fields=['api_calls_count', 'last_api_call'])
        
        return Response({
            'analysis_id': analysis.id,
            **result
        })


class EntityExtractionView(APIView):
    """Entity Extraction endpoint"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = EntityExtractionRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        text = serializer.validated_data['text']
        provider = serializer.validated_data.get('provider', 'auto')
        result = nlp_service.extract_entities(text, provider=provider)
        
        # Save analysis
        analysis = TextAnalysis.objects.create(
            user=request.user,
            input_text=text,
            analysis_type='entities',
            result=result,
            processing_time=result.get('processing_time')
        )
        
        # Update user API usage
        request.user.api_calls_count += 1
        request.user.last_api_call = timezone.now()
        request.user.save(update_fields=['api_calls_count', 'last_api_call'])
        
        return Response({
            'analysis_id': analysis.id,
            **result
        })


class LanguageDetectionView(APIView):
    """Language Detection endpoint"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = LanguageDetectionRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        text = serializer.validated_data['text']
        result = nlp_service.detect_language(text)
        
        # Save analysis
        analysis = TextAnalysis.objects.create(
            user=request.user,
            input_text=text,
            analysis_type='language',
            result=result,
            processing_time=result.get('processing_time')
        )
        
        # Update user API usage
        request.user.api_calls_count += 1
        request.user.last_api_call = timezone.now()
        request.user.save(update_fields=['api_calls_count', 'last_api_call'])
        
        return Response({
            'analysis_id': analysis.id,
            **result
        })


class TranslationView(APIView):
    """Translation endpoint"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = TranslationRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        text = serializer.validated_data['text']
        source_lang = serializer.validated_data.get('source_language', 'auto')
        target_lang = serializer.validated_data.get('target_language', 'en')
        provider = serializer.validated_data.get('provider', 'auto')
        
        result = nlp_service.translate_text(
            text,
            source_lang,
            target_lang,
            provider=provider,
        )
        
        # Save analysis
        analysis = TextAnalysis.objects.create(
            user=request.user,
            input_text=text,
            analysis_type='translation',
            result=result,
            processing_time=result.get('processing_time')
        )
        
        # Update user API usage
        request.user.api_calls_count += 1
        request.user.last_api_call = timezone.now()
        request.user.save(update_fields=['api_calls_count', 'last_api_call'])
        
        return Response({
            'analysis_id': analysis.id,
            **result
        })


class SummarizationView(APIView):
    """Text Summarization endpoint"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = SummarizationRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        text = serializer.validated_data['text']
        max_length = serializer.validated_data.get('max_length', 150)
        min_length = serializer.validated_data.get('min_length', 50)
        provider = serializer.validated_data.get('provider', 'auto')
        
        result = nlp_service.summarize_text(
            text,
            max_length,
            min_length,
            provider=provider,
        )
        
        # Save analysis
        analysis = TextAnalysis.objects.create(
            user=request.user,
            input_text=text,
            analysis_type='summarization',
            result=result,
            processing_time=result.get('processing_time')
        )
        
        # Update user API usage
        request.user.api_calls_count += 1
        request.user.last_api_call = timezone.now()
        request.user.save(update_fields=['api_calls_count', 'last_api_call'])
        
        return Response({
            'analysis_id': analysis.id,
            **result
        })


class ClassificationView(APIView):
    """Text Classification endpoint"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = ClassificationRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        text = serializer.validated_data['text']
        categories = serializer.validated_data.get('categories', [])
        provider = serializer.validated_data.get('provider', 'auto')
        
        result = nlp_service.classify_text(
            text,
            categories if categories else None,
            provider=provider,
        )
        
        # Save analysis
        analysis = TextAnalysis.objects.create(
            user=request.user,
            input_text=text,
            analysis_type='classification',
            result=result,
            processing_time=result.get('processing_time')
        )
        
        # Update user API usage
        request.user.api_calls_count += 1
        request.user.last_api_call = timezone.now()
        request.user.save(update_fields=['api_calls_count', 'last_api_call'])
        
        return Response({
            'analysis_id': analysis.id,
            **result
        })


class NLPHistoryView(APIView):
    """Get NLP analysis history for current user"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        analyses = TextAnalysis.objects.filter(user=request.user)[:50]
        serializer = TextAnalysisSerializer(analyses, many=True)
        return Response(serializer.data)
