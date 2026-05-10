from rest_framework import serializers

from .models import IngestJob, RawRecord


class CollectYouTubeRequestSerializer(serializers.Serializer):
    query = serializers.CharField(max_length=255)
    max_results = serializers.IntegerField(min_value=1, max_value=50, default=20)
    order = serializers.ChoiceField(
        choices=['date', 'rating', 'relevance', 'title', 'videoCount', 'viewCount'],
        default='date'
    )


class CollectFacebookRequestSerializer(serializers.Serializer):
    page_id = serializers.CharField(max_length=100)
    limit = serializers.IntegerField(min_value=1, max_value=100, default=25)


class CollectGoogleMapsRequestSerializer(serializers.Serializer):
    query = serializers.CharField(max_length=255)
    latitude = serializers.FloatField(min_value=-90.0, max_value=90.0)
    longitude = serializers.FloatField(min_value=-180.0, max_value=180.0)
    radius = serializers.IntegerField(min_value=100, max_value=50000, default=2000)
    place_type = serializers.ChoiceField(
        choices=['restaurant', 'cafe', 'lodging', 'bar', 'tourist_attraction'],
        default='restaurant',
    )
    max_results = serializers.IntegerField(min_value=1, max_value=5, default=5)


class RawRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = RawRecord
        fields = [
            'id',
            'source',
            'external_id',
            'title',
            'text',
            'author',
            'metadata',
            'collected_at',
        ]


class IngestJobSerializer(serializers.ModelSerializer):
    class Meta:
        model = IngestJob
        fields = [
            'id',
            'source',
            'query',
            'status',
            'records_count',
            'error_message',
            'started_at',
            'finished_at',
        ]
