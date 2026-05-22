from django.contrib import admin

from .models import Quiz, QuizAttempt, QuizQuestion


class QuizQuestionInline(admin.TabularInline):
    model = QuizQuestion
    extra = 0


@admin.register(Quiz)
class QuizAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "title",
        "topic",
        "difficulty",
        "question_count",
        "created_at",
    )
    search_fields = ("title", "topic", "user__email")
    list_filter = ("difficulty", "created_at")
    inlines = [QuizQuestionInline]


@admin.register(QuizAttempt)
class QuizAttemptAdmin(admin.ModelAdmin):
    list_display = ("id", "quiz", "user", "score", "max_score", "created_at")
    list_filter = ("created_at",)
    search_fields = ("quiz__title", "user__email")
