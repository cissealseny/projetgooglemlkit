from django.contrib import admin

from .models import IngestJob, RawRecord


@admin.register(IngestJob)
class IngestJobAdmin(admin.ModelAdmin):
    list_display = ('id', 'source', 'status', 'records_count', 'started_at', 'finished_at')
    search_fields = ('query', 'error_message', 'source')
    list_filter = ('source', 'status', 'started_at')


@admin.register(RawRecord)
class RawRecordAdmin(admin.ModelAdmin):
    list_display = ('id', 'source', 'external_id', 'author', 'collected_at')
    search_fields = ('external_id', 'title', 'text', 'author')
    list_filter = ('source', 'collected_at')
