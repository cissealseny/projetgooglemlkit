from django.conf import settings
from django.db import models


class Quiz(models.Model):
    """Quiz generated for a user"""

    DIFFICULTY_LEVELS = [
        ("easy", "Easy"),
        ("medium", "Medium"),
        ("hard", "Hard"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="quizzes",
    )
    title = models.CharField(max_length=255)
    topic = models.CharField(max_length=255)
    language = models.CharField(max_length=32, default="auto")
    difficulty = models.CharField(max_length=16, choices=DIFFICULTY_LEVELS)
    question_count = models.PositiveIntegerField(default=10)
    formats = models.JSONField(default=list)
    model = models.CharField(max_length=100, default="ollama:mistral:7b")
    metadata = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "quizzes"
        verbose_name = "Quiz"
        verbose_name_plural = "Quizzes"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} - {self.user.email}"


class QuizQuestion(models.Model):
    """Question belonging to a quiz"""

    QUESTION_TYPES = [
        ("mcq", "Multiple Choice"),
        ("true_false", "True / False"),
        ("open", "Open Answer"),
    ]

    quiz = models.ForeignKey(
        Quiz,
        on_delete=models.CASCADE,
        related_name="questions",
    )
    order = models.PositiveIntegerField(default=1)
    question_type = models.CharField(max_length=20, choices=QUESTION_TYPES)
    prompt = models.TextField()
    options = models.JSONField(default=list, blank=True)
    correct_answer = models.TextField(blank=True)
    explanation = models.TextField(blank=True)
    metadata = models.JSONField(default=dict)

    class Meta:
        db_table = "quiz_questions"
        verbose_name = "Quiz Question"
        verbose_name_plural = "Quiz Questions"
        ordering = ["order"]

    def __str__(self):
        return f"Q{self.order} ({self.question_type}) - {self.quiz_id}"


class QuizAttempt(models.Model):
    """User attempt for a quiz"""

    quiz = models.ForeignKey(
        Quiz,
        on_delete=models.CASCADE,
        related_name="attempts",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="quiz_attempts",
    )
    answers = models.JSONField(default=dict)
    score = models.FloatField(default=0.0)
    max_score = models.PositiveIntegerField(default=0)
    feedback = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "quiz_attempts"
        verbose_name = "Quiz Attempt"
        verbose_name_plural = "Quiz Attempts"
        ordering = ["-created_at"]

    def __str__(self):
        return f"QuizAttempt({self.quiz_id}) - {self.user.email}"
