from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='IngestJob',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('source', models.CharField(choices=[('youtube', 'YouTube Data API'), ('facebook', 'Facebook Graph API')], max_length=20)),
                ('query', models.CharField(blank=True, max_length=255)),
                ('status', models.CharField(choices=[('running', 'Running'), ('success', 'Success'), ('failed', 'Failed')], default='running', max_length=20)),
                ('records_count', models.PositiveIntegerField(default=0)),
                ('error_message', models.TextField(blank=True)),
                ('started_at', models.DateTimeField(auto_now_add=True)),
                ('finished_at', models.DateTimeField(blank=True, null=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='datahub_jobs', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'datahub_ingest_jobs',
                'ordering': ['-started_at'],
            },
        ),
        migrations.CreateModel(
            name='RawRecord',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('source', models.CharField(choices=[('youtube', 'YouTube Data API'), ('facebook', 'Facebook Graph API')], max_length=20)),
                ('external_id', models.CharField(max_length=191)),
                ('title', models.CharField(blank=True, max_length=500)),
                ('text', models.TextField(blank=True)),
                ('author', models.CharField(blank=True, max_length=255)),
                ('metadata', models.JSONField(default=dict)),
                ('collected_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='datahub_records', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'datahub_raw_records',
                'ordering': ['-collected_at'],
            },
        ),
        migrations.AddConstraint(
            model_name='rawrecord',
            constraint=models.UniqueConstraint(fields=('user', 'source', 'external_id'), name='unique_datahub_record_per_user_source_external_id'),
        ),
    ]
