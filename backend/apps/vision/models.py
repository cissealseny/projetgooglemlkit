from django.db import models
from django.conf import settings


class ImageAnalysis(models.Model):
    """Model to store image analysis results"""
    
    ANALYSIS_TYPES = [
        ('ocr', 'OCR - Text Recognition'),
        ('labels', 'Label Detection'),
        ('faces', 'Face Detection'),
        ('objects', 'Object Detection'),
        ('landmarks', 'Landmark Detection'),
        ('logos', 'Logo Detection'),
        ('safe_search', 'Safe Search'),
    ]
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE,
        related_name='image_analyses'
    )
    image = models.ImageField(upload_to='vision/images/')
    analysis_type = models.CharField(max_length=20, choices=ANALYSIS_TYPES)
    result = models.JSONField(default=dict)
    confidence = models.FloatField(null=True, blank=True)
    processing_time = models.FloatField(null=True, blank=True)  # in seconds
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'image_analyses'
        verbose_name = 'Image Analysis'
        verbose_name_plural = 'Image Analyses'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.analysis_type} - {self.user.email} - {self.created_at}"
