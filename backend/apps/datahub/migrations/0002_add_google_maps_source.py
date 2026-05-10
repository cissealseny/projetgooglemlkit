from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('datahub', '0001_initial'),
    ]

    operations = [
        migrations.AlterField(
            model_name='ingestjob',
            name='source',
            field=models.CharField(
                choices=[
                    ('youtube', 'YouTube Data API'),
                    ('facebook', 'Facebook Graph API'),
                    ('google_maps', 'Google Places API'),
                ],
                max_length=20,
            ),
        ),
        migrations.AlterField(
            model_name='rawrecord',
            name='source',
            field=models.CharField(
                choices=[
                    ('youtube', 'YouTube Data API'),
                    ('facebook', 'Facebook Graph API'),
                    ('google_maps', 'Google Places API'),
                ],
                max_length=20,
            ),
        ),
    ]
