from django.contrib import admin

from .models import Conversation, Generation, Message


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ["id", "user", "title", "model", "created_at", "updated_at"]
    list_filter = ["model", "created_at"]
    search_fields = ["user__email", "title"]


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ["id", "conversation", "role", "tokens_used", "created_at"]
    list_filter = ["role", "created_at"]
    search_fields = ["content"]


@admin.register(Generation)
class GenerationAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "user",
        "generation_type",
        "model",
        "tokens_used",
        "created_at",
    ]
    list_filter = ["generation_type", "model", "created_at"]
    search_fields = ["user__email", "prompt"]
