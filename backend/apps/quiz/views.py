from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Quiz, QuizAttempt, QuizQuestion
from .serializers import (
    QuizAttemptSerializer,
    QuizGenerateRequestSerializer,
    QuizGradeRequestSerializer,
    QuizListSerializer,
    QuizSerializer,
)
from .services import quiz_service


class QuizGenerateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = QuizGenerateRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data
        result = quiz_service.generate_quiz(
            topic=data["topic"],
            question_count=data["question_count"],
            difficulty=data["difficulty"],
            formats=data["formats"],
            language=data["language"],
            model=data["model"],
        )

        if not result.get("success"):
            return Response(result, status=status.HTTP_400_BAD_REQUEST)

        quiz_payload = result["quiz"]
        quiz = Quiz.objects.create(
            user=request.user,
            title=quiz_payload["title"],
            topic=quiz_payload["topic"],
            language=quiz_payload["language"],
            difficulty=quiz_payload["difficulty"],
            question_count=quiz_payload["question_count"],
            formats=quiz_payload["formats"],
            model=data["model"],
            metadata={
                "raw_response": result.get("raw", ""),
                "processing_time": result.get("processing_time"),
            },
        )

        for idx, question in enumerate(quiz_payload["questions"], start=1):
            QuizQuestion.objects.create(
                quiz=quiz,
                order=idx,
                question_type=question["question_type"],
                prompt=question["prompt"],
                options=question.get("options", []),
                correct_answer=question.get("correct_answer", ""),
                explanation=question.get("explanation", ""),
            )

        request.user.api_calls_count += 1
        request.user.last_api_call = timezone.now()
        request.user.save(update_fields=["api_calls_count", "last_api_call"])

        return Response(
            {
                "quiz_id": quiz.id,
                "quiz": QuizSerializer(quiz).data,
                "model": result.get("model", data["model"]),
            }
        )


class QuizListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = QuizListSerializer

    def get_queryset(self):
        return Quiz.objects.filter(user=self.request.user)


class QuizDetailView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = QuizSerializer

    def get_queryset(self):
        return Quiz.objects.filter(user=self.request.user)


class QuizAttemptLatestView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        quiz_id = request.query_params.get("quiz_id")
        if not quiz_id:
            return Response(
                {"detail": "quiz_id est requis."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        quiz = get_object_or_404(Quiz, id=quiz_id, user=request.user)
        attempt = (
            QuizAttempt.objects.filter(quiz=quiz, user=request.user)
            .order_by("-created_at")
            .first()
        )

        if not attempt:
            return Response(
                {"detail": "Aucune tentative pour ce quiz."},
                status=status.HTTP_404_NOT_FOUND,
            )

        feedback = attempt.feedback if isinstance(attempt.feedback, dict) else {}
        results = feedback.get("results", []) if isinstance(feedback, dict) else []

        return Response(
            {
                "attempt": QuizAttemptSerializer(attempt).data,
                "score": attempt.score,
                "max_score": attempt.max_score,
                "results": results,
            }
        )


class QuizGradeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = QuizGradeRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        quiz_id = serializer.validated_data["quiz_id"]
        answers_list = serializer.validated_data["answers"]
        model = serializer.validated_data.get("model")
        partial = serializer.validated_data.get("partial", False)
        partial_question_id = serializer.validated_data.get("question_id")

        quiz = get_object_or_404(Quiz, id=quiz_id, user=request.user)
        answers = {item["question_id"]: item["answer"] for item in answers_list}

        results = []
        total_score = 0.0
        max_score = 0

        if partial:
            question = get_object_or_404(
                QuizQuestion,
                id=partial_question_id,
                quiz=quiz,
            )
            user_answer = (answers.get(question.id) or "").strip()

            if question.question_type in ["mcq", "true_false"]:
                correct = self._is_correct_choice(question, user_answer)
                score = 1.0 if correct else 0.0
                feedback = question.explanation or (
                    "Correct" if correct else "Incorrect"
                )
            else:
                evaluation = quiz_service.grade_open_answer(
                    prompt=question.prompt,
                    expected=question.correct_answer,
                    answer=user_answer,
                    language=quiz.language,
                    model=model or quiz.model,
                )
                score = evaluation.get("score", 0.0)
                feedback = evaluation.get("feedback", "")
                correct = score >= 0.6

            results.append(
                {
                    "question_id": question.id,
                    "question_type": question.question_type,
                    "answer": user_answer,
                    "correct_answer": question.correct_answer,
                    "is_correct": correct,
                    "score": score,
                    "explanation": question.explanation,
                    "feedback": feedback,
                }
            )

            request.user.api_calls_count += 1
            request.user.last_api_call = timezone.now()
            request.user.save(update_fields=["api_calls_count", "last_api_call"])

            return Response(
                {
                    "score": score,
                    "max_score": 1,
                    "results": results,
                }
            )

        for question in quiz.questions.all():
            max_score += 1
            user_answer = (answers.get(question.id) or "").strip()

            if question.question_type in ["mcq", "true_false"]:
                correct = self._is_correct_choice(question, user_answer)
                score = 1.0 if correct else 0.0
                feedback = question.explanation or (
                    "Correct" if correct else "Incorrect"
                )
            else:
                evaluation = quiz_service.grade_open_answer(
                    prompt=question.prompt,
                    expected=question.correct_answer,
                    answer=user_answer,
                    language=quiz.language,
                    model=model or quiz.model,
                )
                score = evaluation.get("score", 0.0)
                feedback = evaluation.get("feedback", "")
                correct = score >= 0.6

            total_score += score

            results.append(
                {
                    "question_id": question.id,
                    "question_type": question.question_type,
                    "answer": user_answer,
                    "correct_answer": question.correct_answer,
                    "is_correct": correct,
                    "score": score,
                    "explanation": question.explanation,
                    "feedback": feedback,
                }
            )

        attempt = QuizAttempt.objects.create(
            quiz=quiz,
            user=request.user,
            answers=answers,
            score=total_score,
            max_score=max_score,
            feedback={"results": results},
        )

        request.user.api_calls_count += 1
        request.user.last_api_call = timezone.now()
        request.user.save(update_fields=["api_calls_count", "last_api_call"])

        return Response(
            {
                "attempt": QuizAttemptSerializer(attempt).data,
                "score": total_score,
                "max_score": max_score,
                "results": results,
            }
        )

    def _is_correct_choice(self, question, user_answer: str) -> bool:
        expected = (question.correct_answer or "").strip().lower()
        received = (user_answer or "").strip().lower()
        if not expected:
            return False

        if expected in ["true", "false", "vrai", "faux"]:
            expected = "vrai" if expected == "true" else expected
            expected = "faux" if expected == "false" else expected

        if received in ["true", "false", "vrai", "faux"]:
            received = "vrai" if received == "true" else received
            received = "faux" if received == "false" else received

        return expected == received
