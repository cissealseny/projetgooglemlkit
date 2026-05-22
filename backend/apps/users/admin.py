from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = [
        "email",
        "username",
        "first_name",
        "last_name",
        "api_calls_count",
        "is_active",
        "created_at",
    ]
    list_filter = ["is_active", "is_staff", "created_at"]
    search_fields = ["email", "username", "first_name", "last_name"]
    ordering = ["-created_at"]

    fieldsets = BaseUserAdmin.fieldsets + (
        ("API Usage", {"fields": ("api_calls_count", "last_api_call")}),
        ("Profile", {"fields": ("avatar",)}),
    )
