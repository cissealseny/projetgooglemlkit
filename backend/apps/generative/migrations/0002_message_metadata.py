from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('generative', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='message',
            name='metadata',
            field=models.JSONField(default=dict),
        ),
    ]
