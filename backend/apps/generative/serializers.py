from rest_framework import serializers
from .models import Conversation, Message, Generation


class MessageSerializer(serializers.ModelSerializer):
    places = serializers.SerializerMethodField()
    map_center = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = [
            'id',
            'role',
            'content',
            'metadata',
            'places',
            'map_center',
            'tokens_used',
            'processing_time',
            'created_at',
        ]
        read_only_fields = [
            'id',
            'metadata',
            'places',
            'map_center',
            'tokens_used',
            'processing_time',
            'created_at',
        ]

    def get_places(self, obj):
        metadata = obj.metadata if isinstance(obj.metadata, dict) else {}
        places = metadata.get('places')
        return places if isinstance(places, list) else []

    def get_map_center(self, obj):
        metadata = obj.metadata if isinstance(obj.metadata, dict) else {}
        center = metadata.get('map_center')
        return center if isinstance(center, dict) else None


class ConversationSerializer(serializers.ModelSerializer):
    messages = MessageSerializer(many=True, read_only=True)
    message_count = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = ['id', 'title', 'model', 'messages', 'message_count', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_message_count(self, obj):
        return obj.messages.count()


class ConversationListSerializer(serializers.ModelSerializer):
    message_count = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = ['id', 'title', 'model', 'message_count', 'last_message', 'created_at', 'updated_at']

    def get_message_count(self, obj):
        return obj.messages.count()

    def get_last_message(self, obj):
        last = obj.messages.last()
        return last.content[:100] if last else None


class GenerationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Generation
        fields = ['id', 'generation_type', 'prompt', 'result', 'model',
                  'tokens_used', 'processing_time', 'metadata', 'created_at']
        read_only_fields = ['id', 'result', 'tokens_used', 'processing_time', 'metadata', 'created_at']


# ──────────────────────────────────────────────
#  Modèles disponibles
# ──────────────────────────────────────────────

GEMINI_MODELS = [
    ('gemini:gemini-2.0-flash',  'Gemini 2.0 Flash (Google - Rapide)'),
    ('gemini:gemini-2.5-flash',  'Gemini 2.5 Flash (Google - Dernier)'),
    ('gemini:gemini-2.5-pro',    'Gemini 2.5 Pro (Google - Puissant)'),
]

GPT_MODELS = [
    ('gpt:gpt-4o-mini', 'GPT-4o Mini (OpenAI - Rapide)'),
    ('gpt:gpt-4o',      'GPT-4o (OpenAI - Puissant)'),
    ('gpt:gpt-4-turbo', 'GPT-4 Turbo (OpenAI - Créatif)'),
]

OLLAMA_MODELS = [
    ('ollama:mistral:7b', 'Mistral 7B (Local - Ollama)'),
    ('ollama:llama3.2:1b', 'Llama 3.2 1B (Local - Léger)'),
]

HF_CHAT_MODELS = [
    ('hf:mistralai/Mistral-7B-Instruct-v0.2', 'Mistral 7B (HuggingFace)'),
]

HF_EMBEDDING_MODELS = [
    ('hf:all-MiniLM-L6-v2',  'MiniLM L6 (local, rapide)'),
    ('hf:all-mpnet-base-v2', 'MPNet Base (local, précis)'),
]

ALL_CHAT_MODELS = GEMINI_MODELS + GPT_MODELS + OLLAMA_MODELS + HF_CHAT_MODELS
ALL_GENERAL_MODELS = GEMINI_MODELS + GPT_MODELS + OLLAMA_MODELS + HF_CHAT_MODELS


# Mapping from short aliases to full model names
MODEL_ALIASES = {
    'gemini': 'gemini:gemini-2.0-flash',
    'gpt': 'gpt:gpt-4o-mini',
    'ollama': 'ollama:mistral:7b',
    'mistral': 'ollama:mistral:7b',
    'llama': 'ollama:llama3.2:1b',
    'hf': 'hf:mistralai/Mistral-7B-Instruct-v0.2',
}


class ChatRequestSerializer(serializers.Serializer):
    message         = serializers.CharField(max_length=10000)
    conversation_id = serializers.IntegerField(required=False, allow_null=True)
    model           = serializers.CharField(max_length=100, default='ollama:mistral:7b')
    temperature     = serializers.FloatField(default=0.7, min_value=0.0, max_value=2.0)
    max_tokens      = serializers.IntegerField(default=1024, min_value=1, max_value=8192)
    latitude        = serializers.FloatField(required=False, min_value=-90.0, max_value=90.0)
    longitude       = serializers.FloatField(required=False, min_value=-180.0, max_value=180.0)
    radius_meters   = serializers.IntegerField(required=False, min_value=300, max_value=50000, default=2500)

    def validate_model(self, value):
        """Accept short aliases and convert to full model name."""
        if value in MODEL_ALIASES:
            return MODEL_ALIASES[value]
        # Check if it's a valid full model name
        valid_models = [m[0] for m in ALL_CHAT_MODELS]
        if value not in valid_models:
            # Default to mistral:7b (local, powerful, no quota limits)
            return 'ollama:mistral:7b'
        return value


class TextGenerationRequestSerializer(serializers.Serializer):
    prompt      = serializers.CharField(max_length=10000)
    model       = serializers.ChoiceField(choices=ALL_GENERAL_MODELS, default='gemini:gemini-1.5-flash')
    temperature = serializers.FloatField(default=0.7, min_value=0.0, max_value=2.0)
    max_tokens  = serializers.IntegerField(default=1024, min_value=1, max_value=8192)


class CodeGenerationRequestSerializer(serializers.Serializer):
    prompt   = serializers.CharField(max_length=10000)
    language = serializers.CharField(max_length=50, default='python')
    model    = serializers.ChoiceField(choices=ALL_GENERAL_MODELS, default='gemini:gemini-1.5-flash')


class EmbeddingRequestSerializer(serializers.Serializer):
    text  = serializers.CharField(max_length=10000)
    model = serializers.ChoiceField(choices=HF_EMBEDDING_MODELS, default='hf:all-MiniLM-L6-v2')