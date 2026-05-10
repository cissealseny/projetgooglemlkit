from django.conf import settings
from django.db import models


class IngestJob(models.Model):
    SOURCE_CHOICES = [
        ('youtube', 'YouTube Data API'),
        ('facebook', 'Facebook Graph API'),
        ('google_maps', 'Google Places API'),
    ]

    STATUS_CHOICES = [
        ('running', 'Running'),
        ('success', 'Success'),
        ('failed', 'Failed'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='datahub_jobs'
    )
    source = models.CharField(max_length=20, choices=SOURCE_CHOICES)
    query = models.CharField(max_length=255, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='running')
    records_count = models.PositiveIntegerField(default=0)
    error_message = models.TextField(blank=True)
    started_at = models.DateTimeField(auto_now_add=True)
    finished_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'datahub_ingest_jobs'
        ordering = ['-started_at']

    def __str__(self):
        return f"{self.source} - {self.status} - {self.started_at}"


class RawRecord(models.Model):
    SOURCE_CHOICES = [
        ('youtube', 'YouTube Data API'),
        ('facebook', 'Facebook Graph API'),
        ('google_maps', 'Google Places API'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='datahub_records'
    )
    source = models.CharField(max_length=20, choices=SOURCE_CHOICES)
    external_id = models.CharField(max_length=191)
    title = models.CharField(max_length=500, blank=True)
    text = models.TextField(blank=True)
    author = models.CharField(max_length=255, blank=True)
    metadata = models.JSONField(default=dict)
    collected_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'datahub_raw_records'
        ordering = ['-collected_at']
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'source', 'external_id'],
                name='unique_datahub_record_per_user_source_external_id',
            )
        ]

    def __str__(self):
        return f"{self.source} - {self.external_id}"
