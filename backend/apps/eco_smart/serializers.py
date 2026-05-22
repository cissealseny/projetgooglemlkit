from rest_framework import serializers

SOURCE_CHOICES = [
    "Municipal",
    "Industriel",
    "Commercial",
    "Association",
    "Autre",
]


class EcoSmartBaseRequestSerializer(serializers.Serializer):
    poids = serializers.FloatField(required=False, allow_null=True)
    volume = serializers.FloatField(required=False, allow_null=True)
    conductivite = serializers.FloatField(required=False, allow_null=True)
    opacite = serializers.FloatField(required=False, allow_null=True)
    rigidite = serializers.FloatField(required=False, allow_null=True)
    source = serializers.CharField(
        required=False, allow_blank=True
    )  # Remplacé CharField pour accommoder les barbéchas, etc.
    latitude = serializers.FloatField(required=False, allow_null=True)
    longitude = serializers.FloatField(required=False, allow_null=True)
    rapport_collecte = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=5000,
    )
