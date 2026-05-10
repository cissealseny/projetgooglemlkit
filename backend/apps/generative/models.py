from django.db import models
from django.conf import settings


class Conversation(models.Model):
    """Model to store AI conversations"""
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE,
        related_name='conversations'
    )
    title = models.CharField(max_length=255, blank=True)
    model = models.CharField(max_length=50, default='gemini-pro')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'conversations'
        verbose_name = 'Conversation'
        verbose_name_plural = 'Conversations'
        ordering = ['-updated_at']
    
    def __str__(self):
        return f"{self.title or 'Untitled'} - {self.user.email}"


class Message(models.Model):
    """Model to store conversation messages"""
    
    ROLES = [
        ('user', 'User'),
        ('assistant', 'Assistant'),
        ('system', 'System'),
    ]
    
    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name='messages'
    )
    role = models.CharField(max_length=10, choices=ROLES)
    content = models.TextField()
    metadata = models.JSONField(default=dict)
    tokens_used = models.PositiveIntegerField(default=0)
    processing_time = models.FloatField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'messages'
        verbose_name = 'Message'
        verbose_name_plural = 'Messages'
        ordering = ['created_at']
    
    def __str__(self):
        return f"{self.role}: {self.content[:50]}..."


class Generation(models.Model):
    """Model to store generative AI outputs"""
    
    GENERATION_TYPES = [
        ('text', 'Text Generation'),
        ('code', 'Code Generation'),
        ('image', 'Image Generation'),
        ('embedding', 'Text Embedding'),
    ]
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE,
        related_name='generations'
    )
    generation_type = models.CharField(max_length=20, choices=GENERATION_TYPES)
    prompt = models.TextField()
    result = models.TextField()
    model = models.CharField(max_length=50)
    tokens_used = models.PositiveIntegerField(default=0)
    processing_time = models.FloatField(null=True, blank=True)
    metadata = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'generations'
        verbose_name = 'Generation'
        verbose_name_plural = 'Generations'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.generation_type} - {self.user.email} - {self.created_at}"
