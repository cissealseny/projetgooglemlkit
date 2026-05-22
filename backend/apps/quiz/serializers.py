from rest_framework import serializers

from apps.generative.serializers import ALL_CHAT_MODELS

from .models import Quiz, QuizAttempt, QuizQuestion

QUESTION_TYPE_CHOICES = ["mcq", "true_false", "open"]
DIFFICULTY_CHOICES = ["easy", "medium", "hard"]


class QuizQuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizQuestion
        fields = [
            "id",
            "order",
            "question_type",
            "prompt",
            "options",
            "correct_answer",
            "explanation",
            "metadata",
        ]
        read_only_fields = ["id"]


class QuizSerializer(serializers.ModelSerializer):
    questions = QuizQuestionSerializer(many=True, read_only=True)

    class Meta:
        model = Quiz
        fields = [
            "id",
            "title",
            "topic",
            "language",
            "difficulty",
            "question_count",
            "formats",
            "model",
            "metadata",
            "questions",
            "created_at",
        ]
        read_only_fields = ["id", "metadata", "questions", "created_at"]


class QuizListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Quiz
        fields = [
            "id",
            "title",
            "topic",
            "language",
            "difficulty",
            "question_count",
            "formats",
            "model",
            "created_at",
        ]
        read_only_fields = fields


class QuizGenerateRequestSerializer(serializers.Serializer):
    topic = serializers.CharField(max_length=255)
    question_count = serializers.IntegerField(default=10, min_value=3, max_value=20)
    difficulty = serializers.ChoiceField(choices=DIFFICULTY_CHOICES, default="medium")
    formats = serializers.ListField(
        child=serializers.ChoiceField(choices=QUESTION_TYPE_CHOICES),
        required=False,
        default=list,
    )
    language = serializers.CharField(max_length=32, default="auto")
    model = serializers.ChoiceField(
        choices=ALL_CHAT_MODELS, default="ollama:mistral:7b"
    )

    def validate_formats(self, value):
        formats = value or ["mcq"]
        unique_formats = []
        for item in formats:
            if item not in unique_formats:
                unique_formats.append(item)
        return unique_formats


class QuizAnswerSerializer(serializers.Serializer):
    question_id = serializers.IntegerField()
    answer = serializers.CharField(max_length=2000, allow_blank=True)


class QuizGradeRequestSerializer(serializers.Serializer):
    quiz_id = serializers.IntegerField()
    answers = QuizAnswerSerializer(many=True)
    model = serializers.ChoiceField(choices=ALL_CHAT_MODELS, required=False)
    partial = serializers.BooleanField(required=False, default=False)
    question_id = serializers.IntegerField(required=False)

    def validate(self, attrs):
        if attrs.get("partial"):
            if not attrs.get("question_id"):
                raise serializers.ValidationError(
                    {"question_id": "question_id is required for partial grading."}
                )
        return attrs


class QuizAttemptSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizAttempt
        fields = ["id", "quiz", "score", "max_score", "feedback", "created_at"]
        read_only_fields = fields
