from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """Custom User model with additional fields for ML Kit app"""

    email = models.EmailField(unique=True, max_length=191)
    avatar = models.ImageField(upload_to="avatars/", null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # API usage tracking
    api_calls_count = models.PositiveIntegerField(default=0)
    last_api_call = models.DateTimeField(null=True, blank=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    class Meta:
        db_table = "users"
        verbose_name = "User"
        verbose_name_plural = "Users"

    def __str__(self):
        return self.email


class RecyclingEvent(models.Model):
    """User recycling event for stats (poids, prix, points)."""

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="recycling_events",
    )
    company_name = models.CharField(max_length=200, blank=True, default="")
    city = models.CharField(max_length=120, blank=True, default="")
    zone = models.CharField(max_length=120, blank=True, default="")
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    weight_kg = models.DecimalField(max_digits=8, decimal_places=3)
    price_tnd = models.DecimalField(max_digits=10, decimal_places=3)
    points = models.PositiveIntegerField(default=0)
    waste_type = models.CharField(max_length=50, default="Autre")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "recycling_events"
        verbose_name = "Recycling Event"
        verbose_name_plural = "Recycling Events"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.email} - {self.weight_kg}kg - {self.created_at}"
