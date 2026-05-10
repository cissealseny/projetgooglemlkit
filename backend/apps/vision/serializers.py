from rest_framework import serializers
from .models import ImageAnalysis


class ImageAnalysisSerializer(serializers.ModelSerializer):
    """Serializer for ImageAnalysis model"""
    
    class Meta:
        model = ImageAnalysis
        fields = ['id', 'image', 'analysis_type', 'result', 
                  'confidence', 'processing_time', 'created_at']
        read_only_fields = ['id', 'result', 'confidence', 'processing_time', 'created_at']


class OCRRequestSerializer(serializers.Serializer):
    """Serializer for OCR request"""
    
    image = serializers.ImageField()
    language = serializers.CharField(max_length=10, default='fr')


class ObjectDetectionRequestSerializer(serializers.Serializer):
    """Serializer for object detection request"""
    
    image = serializers.ImageField()
    max_results = serializers.IntegerField(default=10, min_value=1, max_value=100)


class FaceDetectionRequestSerializer(serializers.Serializer):
    """Serializer for face detection request"""
    
    image = serializers.ImageField()
    include_emotions = serializers.BooleanField(default=True)


class ImageLabelingRequestSerializer(serializers.Serializer):
    """Serializer for image labeling request"""
    
    image = serializers.ImageField()
    max_labels = serializers.IntegerField(default=10, min_value=1, max_value=50)
    min_confidence = serializers.FloatField(default=0.5, min_value=0.0, max_value=1.0)
