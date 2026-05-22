import requests
from django.conf import settings
from django.core.cache import cache
from django.db import transaction
from django.http import HttpResponse
from django.utils import timezone
from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import IngestJob, RawRecord
from .serializers import (
    CollectFacebookRequestSerializer,
    CollectGoogleMapsRequestSerializer,
    CollectYouTubeRequestSerializer,
    IngestJobSerializer,
    RawRecordSerializer,
)
from .services import data_collection_service


class CollectYouTubeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CollectYouTubeRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        query = serializer.validated_data["query"]
        max_results = serializer.validated_data.get("max_results", 20)
        order = serializer.validated_data.get("order", "date")

        job = IngestJob.objects.create(
            user=request.user,
            source="youtube",
            query=query,
            status="running",
        )

        result = data_collection_service.collect_youtube(
            query=query,
            max_results=max_results,
            order=order,
        )

        with transaction.atomic():
            created_count = 0
            if result.get("success"):
                for row in result.get("records", []):
                    _, created = RawRecord.objects.update_or_create(
                        user=request.user,
                        source="youtube",
                        external_id=row["external_id"],
                        defaults={
                            "title": row.get("title", ""),
                            "text": row.get("text", ""),
                            "author": row.get("author", ""),
                            "metadata": row.get("metadata", {}),
                        },
                    )
                    if created:
                        created_count += 1

                job.status = "success"
                job.records_count = created_count
                job.finished_at = timezone.now()
                job.save(update_fields=["status", "records_count", "finished_at"])

                request.user.api_calls_count += 1
                request.user.last_api_call = timezone.now()
                request.user.save(update_fields=["api_calls_count", "last_api_call"])

                return Response(
                    {
                        "success": True,
                        "job_id": job.id,
                        "source": "youtube",
                        "query": query,
                        "records_fetched": result.get("count", 0),
                        "records_saved": created_count,
                        "processing_time": result.get("processing_time"),
                    }
                )

            job.status = "failed"
            job.error_message = result.get("error", "Erreur inconnue")
            job.finished_at = timezone.now()
            job.save(update_fields=["status", "error_message", "finished_at"])

            return Response(
                {
                    "success": False,
                    "job_id": job.id,
                    "source": "youtube",
                    "error": result.get("error", "Collecte echouee"),
                    "processing_time": result.get("processing_time"),
                },
                status=400,
            )


class CollectFacebookView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CollectFacebookRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        page_id = serializer.validated_data["page_id"]
        limit = serializer.validated_data.get("limit", 25)

        job = IngestJob.objects.create(
            user=request.user,
            source="facebook",
            query=page_id,
            status="running",
        )

        result = data_collection_service.collect_facebook(page_id=page_id, limit=limit)

        with transaction.atomic():
            created_count = 0
            if result.get("success"):
                for row in result.get("records", []):
                    _, created = RawRecord.objects.update_or_create(
                        user=request.user,
                        source="facebook",
                        external_id=row["external_id"],
                        defaults={
                            "title": row.get("title", ""),
                            "text": row.get("text", ""),
                            "author": row.get("author", ""),
                            "metadata": row.get("metadata", {}),
                        },
                    )
                    if created:
                        created_count += 1

                job.status = "success"
                job.records_count = created_count
                job.finished_at = timezone.now()
                job.save(update_fields=["status", "records_count", "finished_at"])

                request.user.api_calls_count += 1
                request.user.last_api_call = timezone.now()
                request.user.save(update_fields=["api_calls_count", "last_api_call"])

                return Response(
                    {
                        "success": True,
                        "job_id": job.id,
                        "source": "facebook",
                        "page_id": page_id,
                        "records_fetched": result.get("count", 0),
                        "records_saved": created_count,
                        "processing_time": result.get("processing_time"),
                    }
                )

            job.status = "failed"
            job.error_message = result.get("error", "Erreur inconnue")
            job.finished_at = timezone.now()
            job.save(update_fields=["status", "error_message", "finished_at"])

            return Response(
                {
                    "success": False,
                    "job_id": job.id,
                    "source": "facebook",
                    "error": result.get("error", "Collecte echouee"),
                    "processing_time": result.get("processing_time"),
                },
                status=400,
            )


class CollectGoogleMapsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CollectGoogleMapsRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        query = serializer.validated_data["query"]
        latitude = serializer.validated_data["latitude"]
        longitude = serializer.validated_data["longitude"]
        radius = serializer.validated_data.get("radius", 2000)
        place_type = serializer.validated_data.get("place_type", "restaurant")
        max_results = serializer.validated_data.get("max_results", 5)

        job = IngestJob.objects.create(
            user=request.user,
            source="google_maps",
            query=query,
            status="running",
        )

        result = data_collection_service.collect_google_maps(
            query=query,
            latitude=latitude,
            longitude=longitude,
            radius=radius,
            place_type=place_type,
            max_results=max_results,
        )

        with transaction.atomic():
            created_count = 0
            if result.get("success"):
                for row in result.get("records", []):
                    _, created = RawRecord.objects.update_or_create(
                        user=request.user,
                        source="google_maps",
                        external_id=row["external_id"],
                        defaults={
                            "title": row.get("title", ""),
                            "text": row.get("text", ""),
                            "author": row.get("author", ""),
                            "metadata": row.get("metadata", {}),
                        },
                    )
                    if created:
                        created_count += 1

                job.status = "success"
                job.records_count = created_count
                job.finished_at = timezone.now()
                job.save(update_fields=["status", "records_count", "finished_at"])

                request.user.api_calls_count += 1
                request.user.last_api_call = timezone.now()
                request.user.save(update_fields=["api_calls_count", "last_api_call"])

                return Response(
                    {
                        "success": True,
                        "job_id": job.id,
                        "source": "google_maps",
                        "query": query,
                        "records_fetched": result.get("count", 0),
                        "records_saved": created_count,
                        "processing_time": result.get("processing_time"),
                    }
                )

            job.status = "failed"
            job.error_message = result.get("error", "Erreur inconnue")
            job.finished_at = timezone.now()
            job.save(update_fields=["status", "error_message", "finished_at"])

            return Response(
                {
                    "success": False,
                    "job_id": job.id,
                    "source": "google_maps",
                    "error": result.get("error", "Collecte echouee"),
                    "processing_time": result.get("processing_time"),
                },
                status=400,
            )


class RawRecordListView(generics.ListAPIView):
    serializer_class = RawRecordSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = RawRecord.objects.filter(user=self.request.user)
        source = self.request.query_params.get("source")
        if source:
            qs = qs.filter(source=source)
        return qs[:200]


class IngestJobListView(generics.ListAPIView):
    serializer_class = IngestJobSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return IngestJob.objects.filter(user=self.request.user)[:100]


class GooglePlacePhotoProxyView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        photo_reference = (request.query_params.get("photo_reference") or "").strip()
        max_width = request.query_params.get("max_width", "800")

        if not photo_reference:
            return Response(
                {"success": False, "error": "photo_reference requis"}, status=400
            )

        try:
            width = int(max_width)
        except ValueError:
            width = 800
        width = max(120, min(width, 1600))

        if not data_collection_service.google_maps_api_key:
            return Response(
                {"success": False, "error": "GOOGLE_MAPS_API_KEY non configuree"},
                status=503,
            )

        cache_ttl_seconds = int(getattr(settings, "GOOGLE_PLACE_PHOTO_CACHE_TTL", 900))
        cache_key = f"datahub:place-photo:{photo_reference}:{width}"
        cached = cache.get(cache_key)
        if cached:
            response = HttpResponse(
                cached.get("content", b""),
                content_type=cached.get("content_type", "image/jpeg"),
            )
            response["Cache-Control"] = f"public, max-age={cache_ttl_seconds}"
            response["X-Proxy-Cache"] = "HIT"
            return response

        try:
            upstream = requests.get(
                "https://maps.googleapis.com/maps/api/place/photo",
                params={
                    "maxwidth": width,
                    "photo_reference": photo_reference,
                    "key": data_collection_service.google_maps_api_key,
                },
                timeout=30,
                allow_redirects=True,
            )

            if upstream.status_code >= 400:
                return Response(
                    {
                        "success": False,
                        "error": f"Google photo proxy error: HTTP {upstream.status_code}",
                    },
                    status=502,
                )

            content_type = upstream.headers.get("Content-Type", "image/jpeg")
            cache.set(
                cache_key,
                {
                    "content": upstream.content,
                    "content_type": content_type,
                },
                timeout=cache_ttl_seconds,
            )
            response = HttpResponse(upstream.content, content_type=content_type)
            response["Cache-Control"] = f"public, max-age={cache_ttl_seconds}"
            response["X-Proxy-Cache"] = "MISS"
            return response
        except Exception as exc:
            return Response({"success": False, "error": str(exc)}, status=502)
