from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import ImageAnalysis
from .serializers import (FaceDetectionRequestSerializer,
                          ImageAnalysisSerializer,
                          ImageLabelingRequestSerializer,
                          ObjectDetectionRequestSerializer,
                          OCRRequestSerializer)
from .services import vision_service


class OCRView(APIView):
    """OCR - Text Recognition endpoint"""

    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = OCRRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        image = serializer.validated_data["image"]
        language = serializer.validated_data.get("language", "fr")

        result = vision_service.perform_ocr(image, language)

        # Save analysis
        image.seek(0)
        analysis = ImageAnalysis.objects.create(
            user=request.user,
            image=image,
            analysis_type="ocr",
            result=result,
            processing_time=result.get("processing_time"),
        )

        # Update user API usage
        request.user.api_calls_count += 1
        request.user.last_api_call = timezone.now()
        request.user.save(update_fields=["api_calls_count", "last_api_call"])

        return Response({"analysis_id": analysis.id, **result})


class ObjectDetectionView(APIView):
    """Object Detection endpoint"""

    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ObjectDetectionRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        image = serializer.validated_data["image"]
        max_results = serializer.validated_data.get("max_results", 10)

        result = vision_service.detect_objects(image, max_results)

        # Save analysis
        image.seek(0)
        analysis = ImageAnalysis.objects.create(
            user=request.user,
            image=image,
            analysis_type="objects",
            result=result,
            processing_time=result.get("processing_time"),
        )

        # Update user API usage
        request.user.api_calls_count += 1
        request.user.last_api_call = timezone.now()
        request.user.save(update_fields=["api_calls_count", "last_api_call"])

        return Response({"analysis_id": analysis.id, **result})


class FaceDetectionView(APIView):
    """Face Detection endpoint"""

    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = FaceDetectionRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        image = serializer.validated_data["image"]
        include_emotions = serializer.validated_data.get("include_emotions", True)

        result = vision_service.detect_faces(image, include_emotions)

        # Save analysis
        image.seek(0)
        analysis = ImageAnalysis.objects.create(
            user=request.user,
            image=image,
            analysis_type="faces",
            result=result,
            processing_time=result.get("processing_time"),
        )

        # Update user API usage
        request.user.api_calls_count += 1
        request.user.last_api_call = timezone.now()
        request.user.save(update_fields=["api_calls_count", "last_api_call"])

        return Response({"analysis_id": analysis.id, **result})


class ImageLabelingView(APIView):
    """Image Labeling endpoint"""

    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ImageLabelingRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        image = serializer.validated_data["image"]
        max_labels = serializer.validated_data.get("max_labels", 10)
        min_confidence = serializer.validated_data.get("min_confidence", 0.5)

        result = vision_service.label_image(image, max_labels, min_confidence)

        # Save analysis
        image.seek(0)
        analysis = ImageAnalysis.objects.create(
            user=request.user,
            image=image,
            analysis_type="labels",
            result=result,
            processing_time=result.get("processing_time"),
        )

        # Update user API usage
        request.user.api_calls_count += 1
        request.user.last_api_call = timezone.now()
        request.user.save(update_fields=["api_calls_count", "last_api_call"])

        return Response({"analysis_id": analysis.id, **result})


class AnalysisHistoryView(APIView):
    """Get analysis history for current user"""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        analyses = ImageAnalysis.objects.filter(user=request.user)[:50]
        serializer = ImageAnalysisSerializer(analyses, many=True)
        return Response(serializer.data)
