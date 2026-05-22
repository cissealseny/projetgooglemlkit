import csv
from pathlib import Path

from django.conf import settings
from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import EcoSmartBaseRequestSerializer
from .services import build_payload


class _EcoSmartBaseView(APIView):
    permission_classes = [
        permissions.AllowAny if settings.DEBUG else permissions.IsAuthenticated
    ]

    def _update_usage(self, request):
        request.user.api_calls_count += 1
        request.user.last_api_call = timezone.now()
        request.user.save(update_fields=["api_calls_count", "last_api_call"])


class EcoSmartClassificationView(_EcoSmartBaseView):
    def post(self, request):
        serializer = EcoSmartBaseRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payload = build_payload(serializer.validated_data)
        if request.user and request.user.is_authenticated:
            self._update_usage(request)

        return Response(
            {
                "category": payload["category"],
                "confidence": payload["confidence"],
                "prediction_method": payload.get("prediction_method", "heuristic"),
                "location": payload.get("location", {}),
                "model": (
                    "eco-smart-multimodal"
                    if payload.get("prediction_method") == "ml_model"
                    else "eco-smart-baseline"
                ),
            },
            status=status.HTTP_200_OK,
        )


class EcoSmartEstimationView(_EcoSmartBaseView):
    def post(self, request):
        serializer = EcoSmartBaseRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payload = build_payload(serializer.validated_data)
        if request.user and request.user.is_authenticated:
            self._update_usage(request)

        return Response(
            {
                "price": payload["price_tnd"],
                "min_price": payload["min_price_tnd"],
                "max_price": payload["max_price_tnd"],
                "currency": payload.get("currency", "TND"),
                "unit": "kg",
                "prediction_method": payload.get("prediction_method", "heuristic"),
                "location": payload.get("location", {}),
                "model": (
                    "eco-smart-multimodal"
                    if payload.get("prediction_method") == "ml_model"
                    else "eco-smart-baseline"
                ),
            },
            status=status.HTTP_200_OK,
        )


class EcoSmartClusterView(_EcoSmartBaseView):
    def post(self, request):
        serializer = EcoSmartBaseRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payload = build_payload(serializer.validated_data)
        cluster = payload["cluster"]
        if request.user and request.user.is_authenticated:
            self._update_usage(request)

        return Response(
            {
                "cluster_id": cluster["cluster_id"],
                "cluster_label": cluster["cluster_label"],
                "size_hint": cluster["size_hint"],
                "features": cluster["features"],
                "prediction_method": payload.get("prediction_method", "heuristic"),
                "model": (
                    "eco-smart-multimodal"
                    if payload.get("prediction_method") == "ml_model"
                    else "eco-smart-baseline"
                ),
            },
            status=status.HTTP_200_OK,
        )


class EcoSmartNlpView(_EcoSmartBaseView):
    def post(self, request):
        serializer = EcoSmartBaseRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payload = build_payload(serializer.validated_data)
        if request.user and request.user.is_authenticated:
            self._update_usage(request)

        return Response(
            {
                "summary": payload["summary"],
                "keywords": payload["keywords"],
                "report_corrected": payload.get("rapport_collecte_corrige", ""),
                "category": payload["category"],
                "prediction_method": payload.get("prediction_method", "heuristic"),
                "model": (
                    "eco-smart-multimodal"
                    if payload.get("prediction_method") == "ml_model"
                    else "eco-smart-baseline"
                ),
            },
            status=status.HTTP_200_OK,
        )


class EcoSmartMultimodalView(_EcoSmartBaseView):
    def post(self, request):
        serializer = EcoSmartBaseRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payload = build_payload(serializer.validated_data)
        if request.user and request.user.is_authenticated:
            self._update_usage(request)

        return Response(
            {
                "category": payload["category"],
                "confidence": payload["confidence"],
                "price": payload["price_tnd"],
                "currency": payload.get("currency", "TND"),
                "prediction_method": payload.get("prediction_method", "heuristic"),
                "location": payload.get("location", {}),
                "model": (
                    "eco-smart-multimodal"
                    if payload.get("prediction_method") == "ml_model"
                    else "eco-smart-baseline"
                ),
            },
            status=status.HTTP_200_OK,
        )


class EcoSmartCentersView(APIView):
    """Return recycling centers from the local CSV dataset."""

    permission_classes = [
        permissions.AllowAny if settings.DEBUG else permissions.IsAuthenticated
    ]

    def _safe_float(self, value):
        try:
            if value is None or value == "":
                return None
            return float(value)
        except (TypeError, ValueError):
            return None

    def get(self, request):
        csv_path = Path(settings.BASE_DIR) / "dataset_tunisified_base.csv"
        if not csv_path.exists():
            return Response({"centers": []}, status=status.HTTP_200_OK)

        centers = {}
        with csv_path.open("r", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            for row in reader:
                name = (row.get("Source") or "").strip()
                city = (row.get("Ville") or "").strip()
                zone = (row.get("Zone") or "").strip()
                lat = self._safe_float(row.get("Latitude"))
                lon = self._safe_float(row.get("Longitude"))
                if not name or lat is None or lon is None:
                    continue

                key = (name, city, zone, lat, lon)
                entry = centers.get(key)
                if entry is None:
                    entry = {
                        "name": name,
                        "city": city,
                        "zone": zone,
                        "latitude": lat,
                        "longitude": lon,
                        "count": 0,
                        "price_sum": 0.0,
                    }
                    centers[key] = entry

                price = self._safe_float(row.get("Prix_Revente_TND")) or 0.0
                entry["count"] += 1
                entry["price_sum"] += price

        payload = []
        for entry in centers.values():
            count = entry["count"] or 1
            payload.append(
                {
                    "name": entry["name"],
                    "city": entry["city"],
                    "zone": entry["zone"],
                    "latitude": entry["latitude"],
                    "longitude": entry["longitude"],
                    "avg_price_tnd": round(entry["price_sum"] / count, 3),
                }
            )

        payload.sort(key=lambda item: (item["city"], item["name"]))
        return Response({"centers": payload}, status=status.HTTP_200_OK)
