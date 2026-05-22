from django.contrib.auth import authenticate, get_user_model
from django.db.models import Count, Sum
from django.db.models.functions import TruncMonth
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from apps.vision.models import ImageAnalysis

from .models import RecyclingEvent
from .serializers import (ChangePasswordSerializer, LoginSerializer,
                          RecyclingEventCreateSerializer, RegisterSerializer,
                          UserSerializer)

User = get_user_model()


class RegisterView(generics.CreateAPIView):
    """User registration endpoint"""

    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        refresh = RefreshToken.for_user(user)

        return Response(
            {
                "user": UserSerializer(user).data,
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                },
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    """User login endpoint"""

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = authenticate(
            email=serializer.validated_data["email"],
            password=serializer.validated_data["password"],
        )

        if not user:
            return Response(
                {"error": "Identifiants invalides."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        refresh = RefreshToken.for_user(user)

        return Response(
            {
                "user": UserSerializer(user).data,
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                },
            }
        )


class ProfileView(generics.RetrieveUpdateAPIView):
    """User profile endpoint"""

    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class ChangePasswordView(APIView):
    """Change password endpoint"""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(
            data=request.data, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)

        request.user.set_password(serializer.validated_data["new_password"])
        request.user.save()

        return Response({"message": "Mot de passe modifié avec succès."})


class LogoutView(APIView):
    """Logout endpoint - blacklist refresh token"""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data.get("refresh")
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({"message": "Déconnexion réussie."})
        except Exception:
            return Response(
                {"error": "Token invalide."}, status=status.HTTP_400_BAD_REQUEST
            )


class UserStatsView(APIView):
    """Aggregated user stats for dashboard charts."""

    permission_classes = [permissions.IsAuthenticated]

    def _get_month_start(self, year, month):
        return timezone.datetime(year, month, 1, tzinfo=timezone.get_current_timezone())

    def _last_n_months(self, n):
        now = timezone.localtime()
        months = []
        year = now.year
        month = now.month
        for _ in range(n):
            months.append((year, month))
            month -= 1
            if month == 0:
                month = 12
                year -= 1
        return list(reversed(months))

    def get(self, request):
        months = self._last_n_months(6)
        first_year, first_month = months[0]
        period_start = self._get_month_start(first_year, first_month)

        # Aggregate scans by month in Python
        scans_qs = ImageAnalysis.objects.filter(
            user=request.user, created_at__gte=period_start
        ).values_list("created_at", flat=True)
        scans_by_month = {}
        for dt in scans_qs:
            if dt:
                local_dt = timezone.localtime(dt)
                key = local_dt.strftime("%Y-%m")
                scans_by_month[key] = scans_by_month.get(key, 0) + 1

        # Aggregate recycling events weight by month in Python
        events_qs = RecyclingEvent.objects.filter(
            user=request.user, created_at__gte=period_start
        ).values("created_at", "weight_kg")
        kg_by_month = {}
        for item in events_qs:
            dt = item["created_at"]
            if dt:
                local_dt = timezone.localtime(dt)
                key = local_dt.strftime("%Y-%m")
                kg_by_month[key] = kg_by_month.get(key, 0.0) + float(
                    item["weight_kg"] or 0
                )

        scans_total = ImageAnalysis.objects.filter(user=request.user).count()
        totals = RecyclingEvent.objects.filter(user=request.user).aggregate(
            kg=Sum("weight_kg"),
            price_tnd=Sum("price_tnd"),
            points=Sum("points"),
        )

        response_months = []
        for year, month in months:
            key = f"{year:04d}-{month:02d}"
            response_months.append(
                {
                    "month": key,
                    "scans": scans_by_month.get(key, 0),
                    "kg": kg_by_month.get(key, 0.0),
                }
            )

        # Waste type distribution
        waste_qs = (
            RecyclingEvent.objects.filter(user=request.user)
            .values("waste_type")
            .annotate(kg=Sum("weight_kg"))
        )
        waste_distribution = {
            item["waste_type"]: float(item["kg"] or 0) for item in waste_qs
        }

        # Recycling history
        history_events = RecyclingEvent.objects.filter(user=request.user).order_by(
            "-created_at"
        )[:20]
        history_list = []
        for event in history_events:
            history_list.append(
                {
                    "id": event.id,
                    "company_name": event.company_name,
                    "city": event.city,
                    "zone": event.zone,
                    "weight_kg": float(event.weight_kg),
                    "price_tnd": float(event.price_tnd),
                    "points": event.points,
                    "waste_type": event.waste_type,
                    "created_at": event.created_at.isoformat(),
                }
            )

        return Response(
            {
                "api_calls_count": request.user.api_calls_count,
                "scans_total": scans_total,
                "months": response_months,
                "waste_distribution": waste_distribution,
                "history": history_list,
                "totals": {
                    "kg": float(totals["kg"] or 0),
                    "price_tnd": float(totals["price_tnd"] or 0),
                    "points": int(totals["points"] or 0),
                    "count": RecyclingEvent.objects.filter(user=request.user).count(),
                },
            }
        )


class RecyclingEventCreateView(APIView):
    """Create RecyclingEvent entries for the current user (seed)."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        payload = request.data
        events = None

        if isinstance(payload, list):
            events = payload
        elif isinstance(payload, dict) and isinstance(payload.get("events"), list):
            events = payload["events"]
        else:
            events = [payload]

        serializer = RecyclingEventCreateSerializer(data=events, many=True)
        serializer.is_valid(raise_exception=True)

        created = []
        for item in serializer.validated_data:
            created.append(
                RecyclingEvent.objects.create(
                    user=request.user,
                    company_name=item["company_name"],
                    city=item.get("city", ""),
                    zone=item.get("zone", ""),
                    latitude=item.get("latitude"),
                    longitude=item.get("longitude"),
                    weight_kg=item["weight_kg"],
                    price_tnd=item["price_tnd"],
                    points=item["points"],
                    waste_type=item.get("waste_type", "Autre"),
                )
            )

        return Response(
            {
                "created": len(created),
                "total_events": RecyclingEvent.objects.filter(
                    user=request.user
                ).count(),
            },
            status=status.HTTP_201_CREATED,
        )
