"""
Vision AI Services
Provides image analysis capabilities using various ML models
"""

import base64
import os
import time
from io import BytesIO

import numpy as np
from django.conf import settings
from PIL import Image


class VisionService:
    """Service class for Vision AI operations"""

    def __init__(self):
        self.use_google_cloud = bool(settings.GOOGLE_APPLICATION_CREDENTIALS)

    def _image_to_base64(self, image_file):
        """Convert uploaded image to base64"""
        image_data = image_file.read()
        return base64.b64encode(image_data).decode("utf-8")

    def _load_image(self, image_file):
        """Load image using PIL"""
        image_file.seek(0)
        return Image.open(image_file)

    def perform_ocr(self, image_file, language="fr"):
        """
        Perform OCR on the given image
        Returns extracted text
        """
        start_time = time.time()

        try:
            if self.use_google_cloud:
                return self._google_ocr(image_file, language)
            else:
                return self._local_ocr(image_file, language)
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "processing_time": time.time() - start_time,
            }

    def _google_ocr(self, image_file, language):
        """OCR using Google Cloud Vision API"""
        from google.cloud import vision

        start_time = time.time()
        client = vision.ImageAnnotatorClient()

        content = image_file.read()
        image = vision.Image(content=content)

        response = client.text_detection(
            image=image, image_context={"language_hints": [language]}
        )

        texts = response.text_annotations

        if texts:
            return {
                "success": True,
                "text": texts[0].description,
                "blocks": [
                    {
                        "text": text.description,
                        "confidence": getattr(text, "confidence", None),
                        "bounding_box": [
                            {"x": vertex.x, "y": vertex.y}
                            for vertex in text.bounding_poly.vertices
                        ],
                    }
                    for text in texts[1:]
                ],
                "processing_time": time.time() - start_time,
            }

        return {
            "success": True,
            "text": "",
            "blocks": [],
            "processing_time": time.time() - start_time,
        }

    def _local_ocr(self, image_file, language):
        """Local OCR fallback (placeholder)"""
        start_time = time.time()

        # Placeholder - in production, use pytesseract or similar
        return {
            "success": True,
            "text": "[OCR requires Google Cloud Vision API or local Tesseract setup]",
            "blocks": [],
            "processing_time": time.time() - start_time,
            "note": "Using local fallback",
        }

    def detect_objects(self, image_file, max_results=10):
        """
        Detect objects in the given image
        Returns list of detected objects with bounding boxes
        """
        start_time = time.time()

        try:
            if self.use_google_cloud:
                return self._google_object_detection(image_file, max_results)
            else:
                return self._local_object_detection(image_file, max_results)
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "processing_time": time.time() - start_time,
            }

    def _google_object_detection(self, image_file, max_results):
        """Object detection using Google Cloud Vision API"""
        from google.cloud import vision

        start_time = time.time()
        client = vision.ImageAnnotatorClient()

        content = image_file.read()
        image = vision.Image(content=content)

        response = client.object_localization(image=image, max_results=max_results)

        objects = response.localized_object_annotations

        return {
            "success": True,
            "objects": [
                {
                    "name": obj.name,
                    "confidence": obj.score,
                    "bounding_box": [
                        {"x": vertex.x, "y": vertex.y}
                        for vertex in obj.bounding_poly.normalized_vertices
                    ],
                }
                for obj in objects
            ],
            "count": len(objects),
            "processing_time": time.time() - start_time,
        }

    def _local_object_detection(self, image_file, max_results):
        """Local object detection fallback"""
        start_time = time.time()

        return {
            "success": True,
            "objects": [],
            "count": 0,
            "processing_time": time.time() - start_time,
            "note": "Using local fallback - configure Google Cloud for full functionality",
        }

    def detect_faces(self, image_file, include_emotions=True):
        """
        Detect faces in the given image
        Returns list of detected faces with landmarks and emotions
        """
        start_time = time.time()

        try:
            if self.use_google_cloud:
                return self._google_face_detection(image_file, include_emotions)
            else:
                return self._local_face_detection(image_file, include_emotions)
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "processing_time": time.time() - start_time,
            }

    def _google_face_detection(self, image_file, include_emotions):
        """Face detection using Google Cloud Vision API"""
        from google.cloud import vision

        start_time = time.time()
        client = vision.ImageAnnotatorClient()

        content = image_file.read()
        image = vision.Image(content=content)

        response = client.face_detection(image=image)
        faces = response.face_annotations

        likelihood_name = [
            "UNKNOWN",
            "VERY_UNLIKELY",
            "UNLIKELY",
            "POSSIBLE",
            "LIKELY",
            "VERY_LIKELY",
        ]

        result_faces = []
        for face in faces:
            face_data = {
                "confidence": face.detection_confidence,
                "bounding_box": [
                    {"x": vertex.x, "y": vertex.y}
                    for vertex in face.bounding_poly.vertices
                ],
            }

            if include_emotions:
                face_data["emotions"] = {
                    "joy": likelihood_name[face.joy_likelihood],
                    "sorrow": likelihood_name[face.sorrow_likelihood],
                    "anger": likelihood_name[face.anger_likelihood],
                    "surprise": likelihood_name[face.surprise_likelihood],
                }

            result_faces.append(face_data)

        return {
            "success": True,
            "faces": result_faces,
            "count": len(result_faces),
            "processing_time": time.time() - start_time,
        }

    def _local_face_detection(self, image_file, include_emotions):
        """Local face detection fallback"""
        start_time = time.time()

        return {
            "success": True,
            "faces": [],
            "count": 0,
            "processing_time": time.time() - start_time,
            "note": "Using local fallback",
        }

    def label_image(self, image_file, max_labels=10, min_confidence=0.5):
        """
        Label/classify the given image
        Returns list of labels with confidence scores
        """
        start_time = time.time()

        try:
            if self.use_google_cloud:
                return self._google_label_detection(
                    image_file, max_labels, min_confidence
                )
            else:
                return self._local_label_detection(
                    image_file, max_labels, min_confidence
                )
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "processing_time": time.time() - start_time,
            }

    def _google_label_detection(self, image_file, max_labels, min_confidence):
        """Label detection using Google Cloud Vision API"""
        from google.cloud import vision

        start_time = time.time()
        client = vision.ImageAnnotatorClient()

        content = image_file.read()
        image = vision.Image(content=content)

        response = client.label_detection(image=image, max_results=max_labels)
        labels = response.label_annotations

        filtered_labels = [
            {
                "name": label.description,
                "confidence": label.score,
                "topicality": label.topicality,
            }
            for label in labels
            if label.score >= min_confidence
        ]

        return {
            "success": True,
            "labels": filtered_labels,
            "count": len(filtered_labels),
            "processing_time": time.time() - start_time,
        }

    def _local_label_detection(self, image_file, max_labels, min_confidence):
        """Local label detection fallback"""
        start_time = time.time()

        return {
            "success": True,
            "labels": [],
            "count": 0,
            "processing_time": time.time() - start_time,
            "note": "Using local fallback",
        }


# Singleton instance
vision_service = VisionService()
