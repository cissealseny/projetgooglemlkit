# Generated manually for quiz app
from django.db import migrations, models
import django.db.models.deletion
from django.conf import settings


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Quiz',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=255)),
                ('topic', models.CharField(max_length=255)),
                ('language', models.CharField(default='auto', max_length=32)),
                ('difficulty', models.CharField(choices=[('easy', 'Easy'), ('medium', 'Medium'), ('hard', 'Hard')], max_length=16)),
                ('question_count', models.PositiveIntegerField(default=10)),
                ('formats', models.JSONField(default=list)),
                ('model', models.CharField(default='ollama:mistral:7b', max_length=100)),
                ('metadata', models.JSONField(default=dict)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='quizzes', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Quiz',
                'verbose_name_plural': 'Quizzes',
                'db_table': 'quizzes',
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='QuizQuestion',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('order', models.PositiveIntegerField(default=1)),
                ('question_type', models.CharField(choices=[('mcq', 'Multiple Choice'), ('true_false', 'True / False'), ('open', 'Open Answer')], max_length=20)),
                ('prompt', models.TextField()),
                ('options', models.JSONField(blank=True, default=list)),
                ('correct_answer', models.TextField(blank=True)),
                ('explanation', models.TextField(blank=True)),
                ('metadata', models.JSONField(default=dict)),
                ('quiz', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='questions', to='quiz.quiz')),
            ],
            options={
                'verbose_name': 'Quiz Question',
                'verbose_name_plural': 'Quiz Questions',
                'db_table': 'quiz_questions',
                'ordering': ['order'],
            },
        ),
        migrations.CreateModel(
            name='QuizAttempt',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('answers', models.JSONField(default=dict)),
                ('score', models.FloatField(default=0.0)),
                ('max_score', models.PositiveIntegerField(default=0)),
                ('feedback', models.JSONField(default=dict)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('quiz', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='attempts', to='quiz.quiz')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='quiz_attempts', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Quiz Attempt',
                'verbose_name_plural': 'Quiz Attempts',
                'db_table': 'quiz_attempts',
                'ordering': ['-created_at'],
            },
        ),
    ]
