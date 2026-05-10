from rest_framework import status, permissions, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils import timezone
from django.shortcuts import get_object_or_404
import re
import math
import requests
import logging

from .models import Conversation, Message, Generation
from .serializers import (
    ConversationSerializer,
    ConversationListSerializer,
    MessageSerializer,
    GenerationSerializer,
    ChatRequestSerializer,
    TextGenerationRequestSerializer,
    CodeGenerationRequestSerializer,
    EmbeddingRequestSerializer
)
from .services import generative_service
from apps.datahub.services import data_collection_service
from apps.datahub.models import RawRecord


logger = logging.getLogger(__name__)


class ChatView(APIView):
    """Chat endpoint for conversational AI"""
    
    permission_classes = [permissions.IsAuthenticated]

    PLACE_INTENT_PATTERN = re.compile(
        r'(proche|autour|nearby|pres de moi|près de moi|restaurant|cafe|caf[eé]|hotel|h[oô]tel|cuisine|manger|fast\s*food|snack|diner|dîner|dejeuner|déjeuner)',
        re.IGNORECASE,
    )
    DEFAULT_FALLBACK_LATITUDE = 36.8065
    DEFAULT_FALLBACK_LONGITUDE = 10.1815
    
    def post(self, request):
        serializer = ChatRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        message_content = serializer.validated_data['message']
        conversation_id = serializer.validated_data.get('conversation_id')
        model = serializer.validated_data.get('model', 'gemini-pro')
        temperature = serializer.validated_data.get('temperature', 0.7)
        max_tokens = serializer.validated_data.get('max_tokens', 1024)
        latitude = serializer.validated_data.get('latitude')
        longitude = serializer.validated_data.get('longitude')
        radius_meters = serializer.validated_data.get('radius_meters', 2500)
        
        # Get or create conversation
        if conversation_id:
            conversation = get_object_or_404(
                Conversation, 
                id=conversation_id, 
                user=request.user
            )
        else:
            conversation = Conversation.objects.create(
                user=request.user,
                title=message_content[:50],
                model=model
            )
        
        # Save user message
        user_message = Message.objects.create(
            conversation=conversation,
            role='user',
            content=message_content
        )
        
        # Build message history
        messages = [
            {'role': msg.role, 'content': msg.content}
            for msg in conversation.messages.all()
        ]

        nearby_result = self._maybe_collect_nearby_places(
            request=request,
            message=message_content,
            latitude=latitude,
            longitude=longitude,
            radius_meters=radius_meters,
            user=request.user,
        )

        if nearby_result.get('used_places'):
            places = nearby_result.get('places', [])
            user_prompt = self._build_places_prompt(message_content, places)
            messages.append({'role': 'system', 'content': user_prompt})
        
        # Get AI response
        result = generative_service.chat(messages, model, temperature, max_tokens)

        if result.get('success') and nearby_result.get('used_places'):
            result['places'] = nearby_result.get('places', [])
            result['map_center'] = nearby_result.get('map_center')
            result['places_context'] = {
                'query': nearby_result.get('query'),
                'place_type': (nearby_result.get('place_types') or [None])[0],
                'place_types': nearby_result.get('place_types', []),
                'providers': nearby_result.get('providers', []),
                'fallback_reasons': nearby_result.get('fallback_reasons', []),
            }
        
        # Save assistant message
        if result.get('success'):
            assistant_metadata = {}
            if isinstance(result.get('places'), list):
                assistant_metadata['places'] = result.get('places', [])
            if isinstance(result.get('map_center'), dict):
                assistant_metadata['map_center'] = result.get('map_center')
            if isinstance(result.get('places_context'), dict):
                assistant_metadata['places_context'] = result.get('places_context')

            assistant_message = Message.objects.create(
                conversation=conversation,
                role='assistant',
                content=result['response'],
                metadata=assistant_metadata,
                tokens_used=result.get('tokens_used', 0),
                processing_time=result.get('processing_time')
            )
            
            # Update conversation
            conversation.save()  # Updates updated_at
            
            # Update user API usage
            request.user.api_calls_count += 1
            request.user.last_api_call = timezone.now()
            request.user.save(update_fields=['api_calls_count', 'last_api_call'])
        
        return Response({
            'conversation_id': conversation.id,
            'message': MessageSerializer(assistant_message).data if result.get('success') else None,
            **result
        })

    def _maybe_collect_nearby_places(self, request, message, latitude, longitude, radius_meters, user):
        if not self.PLACE_INTENT_PATTERN.search(message or ''):
            return {'used_places': False}

        if latitude is None or longitude is None:
            inferred_coords = self._infer_coordinates_from_message(message)
            if inferred_coords is None:
                return {'used_places': False}
            latitude, longitude = inferred_coords

        query, categories = self._extract_place_categories(message)
        places = []
        providers = set()
        fallback_reasons = []

        for place_type in categories:
            result = data_collection_service.collect_google_maps(
                query=query,
                latitude=latitude,
                longitude=longitude,
                radius=radius_meters,
                place_type=place_type,
                max_results=5,
            )

            if not result.get('success'):
                logger.warning(
                    'Nearby places fetch failed | user_id=%s query="%s" place_type=%s error=%s',
                    user.id,
                    query,
                    place_type,
                    result.get('error'),
                )
                continue

            provider = (result.get('provider') or 'unknown').strip() or 'unknown'
            providers.add(provider)

            fallback_reason = (result.get('fallback_reason') or '').strip()
            if fallback_reason and fallback_reason not in fallback_reasons:
                fallback_reasons.append(fallback_reason)

            log_message = (
                'Nearby places fetch source=%s | user_id=%s query="%s" '
                'place_type=%s count=%s fallback_reason="%s"'
            )
            log_args = (
                provider,
                user.id,
                query,
                place_type,
                result.get('count', 0),
                fallback_reason,
            )

            if provider != 'google_places':
                logger.warning(log_message, *log_args)
            else:
                logger.info(log_message, *log_args)

            self._persist_google_maps_records(user, result.get('records', []))

            for row in result.get('records', []):
                metadata = row.get('metadata') or {}
                place_lat = metadata.get('latitude')
                place_lng = metadata.get('longitude')
                distance_meters = self._compute_distance_meters(
                    latitude,
                    longitude,
                    place_lat,
                    place_lng,
                )
                places.append({
                    'id': row.get('external_id'),
                    'name': row.get('title', ''),
                    'address': row.get('text', ''),
                    'rating': metadata.get('rating'),
                    'user_ratings_total': metadata.get('user_ratings_total', 0),
                    'open_now': metadata.get('open_now'),
                    'latitude': place_lat,
                    'longitude': place_lng,
                    'distance_meters': distance_meters,
                    'maps_url': metadata.get('maps_url'),
                    'photo_proxy_url': self._build_place_photo_proxy_url(request, metadata.get('photo_reference'), max_width=900),
                    'thumbnail_proxy_url': self._build_place_photo_proxy_url(request, metadata.get('photo_reference'), max_width=480),
                    'place_type': metadata.get('place_type', place_type),
                })

        places = self._rank_places(places, radius_meters)

        if not places:
            return {'used_places': False}

        return {
            'used_places': True,
            'query': query,
            'place_types': categories,
            'providers': sorted(providers),
            'fallback_reasons': fallback_reasons,
            'places': places,
            'map_center': {
                'latitude': latitude,
                'longitude': longitude,
            },
        }

    def _infer_coordinates_from_message(self, message):
        text = (message or '').strip()
        if not text:
            return None

        params = {
            'q': text,
            'format': 'jsonv2',
            'limit': 1,
        }
        headers = {
            'User-Agent': 'GoogleMLKit/1.0 (nearby-chat-fallback)',
        }

        try:
            response = requests.get(
                'https://nominatim.openstreetmap.org/search',
                params=params,
                headers=headers,
                timeout=6,
            )
            response.raise_for_status()
            payload = response.json()
        except Exception:
            return (
                self.DEFAULT_FALLBACK_LATITUDE,
                self.DEFAULT_FALLBACK_LONGITUDE,
            )

        if not isinstance(payload, list) or not payload:
            return (
                self.DEFAULT_FALLBACK_LATITUDE,
                self.DEFAULT_FALLBACK_LONGITUDE,
            )

        first = payload[0] or {}
        try:
            return float(first.get('lat')), float(first.get('lon'))
        except (TypeError, ValueError):
            return (
                self.DEFAULT_FALLBACK_LATITUDE,
                self.DEFAULT_FALLBACK_LONGITUDE,
            )

    def _rank_places(self, places, radius_meters):
        def _score(place):
            rating = place.get('rating')
            try:
                rating = float(rating)
            except (TypeError, ValueError):
                rating = 0.0

            distance = place.get('distance_meters')
            try:
                distance = float(distance)
            except (TypeError, ValueError):
                distance = float(radius_meters)

            rating_norm = max(0.0, min(rating / 5.0, 1.0))
            distance_norm = max(0.0, min(distance / float(max(radius_meters, 1)), 1.0))
            proximity = 1.0 - distance_norm

            return (0.65 * rating_norm) + (0.35 * proximity)

        ranked = sorted(places, key=_score, reverse=True)
        return ranked

    def _compute_distance_meters(self, lat1, lon1, lat2, lon2):
        try:
            lat1 = float(lat1)
            lon1 = float(lon1)
            lat2 = float(lat2)
            lon2 = float(lon2)
        except (TypeError, ValueError):
            return None

        radius_earth = 6371000.0
        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        delta_phi = math.radians(lat2 - lat1)
        delta_lambda = math.radians(lon2 - lon1)

        a = (
            math.sin(delta_phi / 2.0) ** 2
            + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
        )
        c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
        return round(radius_earth * c, 1)

    def _extract_place_categories(self, message):
        text = (message or '').strip()
        text_lower = text.lower()

        if 'fast food' in text_lower or 'fastfood' in text_lower or 'snack' in text_lower:
            return text or 'fast food', ['restaurant']

        if 'hotel' in text_lower or 'hôtel' in text_lower:
            return 'hotel', ['lodging']
        if 'cafe' in text_lower or 'café' in text_lower:
            return 'cafe', ['cafe']
        if 'bar' in text_lower:
            return 'bar', ['bar']
        if 'attraction' in text_lower or 'touristique' in text_lower:
            return 'tourist attraction', ['tourist_attraction']

        if 'cuisine' in text_lower or 'manger' in text_lower or 'repas' in text_lower:
            return text or 'restaurant', ['restaurant', 'cafe']

        # Recherche generique: retourner 5 resultats par categorie principale.
        return 'restaurant', ['restaurant', 'cafe', 'lodging']

    def _persist_google_maps_records(self, user, records):
        for row in records:
            external_id = row.get('external_id')
            if not external_id:
                continue
            RawRecord.objects.update_or_create(
                user=user,
                source='google_maps',
                external_id=external_id,
                defaults={
                    'title': row.get('title', ''),
                    'text': row.get('text', ''),
                    'author': row.get('author', 'google_places'),
                    'metadata': row.get('metadata', {}),
                },
            )

    def _build_place_photo_proxy_url(self, request, photo_reference, max_width=900):
        if not photo_reference:
            return ''
        base = request.build_absolute_uri('/api/v1/datahub/google-place-photo/')
        return f'{base}?photo_reference={photo_reference}&max_width={int(max_width)}'

    def _build_places_prompt(self, user_message, places):
        lines = []
        for idx, place in enumerate(places[:5], start=1):
            lines.append(
                f"{idx}. {place.get('name', '')} | {place.get('address', '')} | rating={place.get('rating', 'N/A')}"
            )

        places_block = '\n'.join(lines) if lines else 'Aucun lieu trouve.'
        return (
            "Tu as des resultats geolocalises fiables depuis Google Places. "
            "Reponds en francais avec recommandation courte, puis liste numerotee concise. "
            f"Question utilisateur: {user_message}\n"
            f"Lieux disponibles:\n{places_block}"
        )


class ConversationListView(generics.ListCreateAPIView):
    """List user's conversations or create a new one"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ConversationSerializer
        return ConversationListSerializer
    
    def get_queryset(self):
        return Conversation.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class ConversationDetailView(generics.RetrieveDestroyAPIView):
    """Get or delete a conversation"""
    
    serializer_class = ConversationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Conversation.objects.filter(user=self.request.user)


class TextGenerationView(APIView):
    """Text generation endpoint"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = TextGenerationRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        prompt = serializer.validated_data['prompt']
        model = serializer.validated_data.get('model', 'gemini-pro')
        temperature = serializer.validated_data.get('temperature', 0.7)
        max_tokens = serializer.validated_data.get('max_tokens', 1024)
        
        result = generative_service.generate_text(prompt, model, temperature, max_tokens)
        
        # Save generation
        if result.get('success'):
            generation = Generation.objects.create(
                user=request.user,
                generation_type='text',
                prompt=prompt,
                result=result.get('response', ''),
                model=model,
                tokens_used=result.get('tokens_used', 0),
                processing_time=result.get('processing_time')
            )
            
            # Update user API usage
            request.user.api_calls_count += 1
            request.user.last_api_call = timezone.now()
            request.user.save(update_fields=['api_calls_count', 'last_api_call'])
            
            result['generation_id'] = generation.id
        
        return Response(result)


class CodeGenerationView(APIView):
    """Code generation endpoint"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = CodeGenerationRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        prompt = serializer.validated_data['prompt']
        language = serializer.validated_data.get('language', 'python')
        model = serializer.validated_data.get('model', 'gemini-pro')
        
        result = generative_service.generate_code(prompt, language, model)
        
        # Save generation
        if result.get('success'):
            generation = Generation.objects.create(
                user=request.user,
                generation_type='code',
                prompt=prompt,
                result=result.get('response', ''),
                model=model,
                tokens_used=result.get('tokens_used', 0),
                processing_time=result.get('processing_time'),
                metadata={'language': language}
            )
            
            # Update user API usage
            request.user.api_calls_count += 1
            request.user.last_api_call = timezone.now()
            request.user.save(update_fields=['api_calls_count', 'last_api_call'])
            
            result['generation_id'] = generation.id
        
        return Response(result)


class EmbeddingView(APIView):
    """Text embedding endpoint"""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = EmbeddingRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        text = serializer.validated_data['text']
        model = serializer.validated_data.get('model', 'text-embedding-ada-002')
        
        result = generative_service.generate_embedding(text, model)
        
        # Save generation
        if result.get('success'):
            generation = Generation.objects.create(
                user=request.user,
                generation_type='embedding',
                prompt=text,
                result=str(result.get('dimensions', 0)) + ' dimensions',
                model=model,
                tokens_used=result.get('tokens_used', 0),
                processing_time=result.get('processing_time'),
                metadata={'dimensions': result.get('dimensions')}
            )
            
            # Update user API usage
            request.user.api_calls_count += 1
            request.user.last_api_call = timezone.now()
            request.user.save(update_fields=['api_calls_count', 'last_api_call'])
            
            result['generation_id'] = generation.id
        
        return Response(result)


class GenerationHistoryView(generics.ListAPIView):
    """List user's generations"""
    
    serializer_class = GenerationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Generation.objects.filter(user=self.request.user)[:50]
