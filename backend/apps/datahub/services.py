import os
import time

import requests
from django.conf import settings


class DataCollectionService:
    def __init__(self):
        self.youtube_api_key = os.getenv('YOUTUBE_API_KEY', '')
        self.facebook_access_token = os.getenv('FACEBOOK_ACCESS_TOKEN', '')
        self.google_maps_api_key = os.getenv('GOOGLE_MAPS_API_KEY', '')

    def collect_youtube(self, query, max_results=20, order='date'):
        start_time = time.time()

        if not self.youtube_api_key:
            return {
                'success': False,
                'error': 'YOUTUBE_API_KEY non configuree',
                'records': [],
                'processing_time': time.time() - start_time,
            }

        try:
            from googleapiclient.discovery import build
        except Exception:
            return {
                'success': False,
                'error': 'Dependance manquante: installe google-api-python-client',
                'records': [],
                'processing_time': time.time() - start_time,
            }

        try:
            client = build('youtube', 'v3', developerKey=self.youtube_api_key)
            response = client.search().list(
                q=query,
                part='snippet',
                type='video',
                maxResults=max_results,
                order=order,
            ).execute()

            video_ids = [
                (item.get('id') or {}).get('videoId')
                for item in response.get('items', [])
                if (item.get('id') or {}).get('videoId')
            ]

            stats_by_id = {}
            if video_ids:
                details = client.videos().list(
                    part='statistics,contentDetails,snippet',
                    id=','.join(video_ids),
                ).execute()
                for video in details.get('items', []):
                    video_id = video.get('id')
                    if not video_id:
                        continue
                    stats_by_id[video_id] = {
                        'statistics': video.get('statistics', {}),
                        'content_details': video.get('contentDetails', {}),
                        'snippet': video.get('snippet', {}),
                    }

            records = []
            for item in response.get('items', []):
                snippet = item.get('snippet', {})
                video_id = (item.get('id') or {}).get('videoId')
                if not video_id:
                    continue

                details = stats_by_id.get(video_id, {})
                statistics = details.get('statistics', {})
                content_details = details.get('content_details', {})
                snippet_details = details.get('snippet', {})

                records.append({
                    'source': 'youtube',
                    'external_id': video_id,
                    'title': snippet.get('title', ''),
                    'text': snippet.get('description', ''),
                    'author': snippet.get('channelTitle', ''),
                    'metadata': {
                        'published_at': snippet.get('publishedAt'),
                        'channel_id': snippet.get('channelId'),
                        'channel_title': snippet_details.get('channelTitle', ''),
                        'thumbnails': snippet.get('thumbnails', {}),
                        'duration': content_details.get('duration'),
                        'view_count': self._safe_int(statistics.get('viewCount')),
                        'like_count': self._safe_int(statistics.get('likeCount')),
                        'comment_count': self._safe_int(statistics.get('commentCount')),
                        'favorite_count': self._safe_int(statistics.get('favoriteCount')),
                        'query': query,
                        'order': order,
                    },
                })

            return {
                'success': True,
                'records': records,
                'count': len(records),
                'processing_time': time.time() - start_time,
            }
        except Exception as exc:
            return {
                'success': False,
                'error': str(exc),
                'records': [],
                'processing_time': time.time() - start_time,
            }

    def collect_facebook(self, page_id, limit=25):
        start_time = time.time()

        if not self.facebook_access_token:
            return {
                'success': False,
                'error': 'FACEBOOK_ACCESS_TOKEN non configure',
                'records': [],
                'processing_time': time.time() - start_time,
            }

        url = f'https://graph.facebook.com/v22.0/{page_id}/posts'
        params = {
            'access_token': self.facebook_access_token,
            'fields': (
                'id,message,created_time,permalink_url,from,shares,'
                'reactions.summary(true),comments.summary(true)'
            ),
            'limit': limit,
        }

        try:
            response = requests.get(url, params=params, timeout=30)
            payload = response.json()

            if response.status_code >= 400 or payload.get('error'):
                err = payload.get('error', {}).get('message', 'Erreur Facebook Graph API')
                return {
                    'success': False,
                    'error': err,
                    'records': [],
                    'processing_time': time.time() - start_time,
                }

            records = []
            for post in payload.get('data', []):
                post_id = post.get('id')
                if not post_id:
                    continue

                author = ''
                author_data = post.get('from') or {}
                if isinstance(author_data, dict):
                    author = author_data.get('name', '')

                records.append({
                    'source': 'facebook',
                    'external_id': post_id,
                    'title': f'Post {post_id}',
                    'text': post.get('message', ''),
                    'author': author,
                    'metadata': {
                        'created_time': post.get('created_time'),
                        'permalink_url': post.get('permalink_url'),
                        'page_id': page_id,
                        'reactions_count': self._safe_int(
                            ((post.get('reactions') or {}).get('summary') or {}).get('total_count')
                        ),
                        'comments_count': self._safe_int(
                            ((post.get('comments') or {}).get('summary') or {}).get('total_count')
                        ),
                        'shares_count': self._safe_int((post.get('shares') or {}).get('count')),
                    },
                })

            return {
                'success': True,
                'records': records,
                'count': len(records),
                'processing_time': time.time() - start_time,
            }
        except Exception as exc:
            return {
                'success': False,
                'error': str(exc),
                'records': [],
                'processing_time': time.time() - start_time,
            }

    def _safe_int(self, value):
        try:
            if value is None:
                return 0
            return int(value)
        except (TypeError, ValueError):
            return 0

    def _collect_osm_places(self, query, latitude, longitude, radius, place_type, max_results, start_time, fallback_reason=''):
        capped_results = min(max(int(max_results or 5), 1), 5)

        # Minimal mapping from app place types to common OSM tags.
        if place_type == 'lodging':
            key, value = 'tourism', 'hotel'
        elif place_type == 'cafe':
            key, value = 'amenity', 'cafe'
        else:
            key, value = 'amenity', 'restaurant'

        overpass_query = (
            '[out:json][timeout:25];'
            '('
            f'node(around:{int(radius)},{latitude},{longitude})["{key}"="{value}"];'
            f'way(around:{int(radius)},{latitude},{longitude})["{key}"="{value}"];'
            f'relation(around:{int(radius)},{latitude},{longitude})["{key}"="{value}"];'
            ');'
            'out center tags;'
        )

        try:
            response = requests.post('https://overpass-api.de/api/interpreter', data=overpass_query, timeout=30)
            payload = response.json()
            elements = payload.get('elements', []) if isinstance(payload, dict) else []

            records = []
            query_lower = (query or '').strip().lower()
            generic_queries = {
                'restaurant',
                'cafe',
                'café',
                'hotel',
                'hôtel',
                'bar',
                'snack',
                'fast food',
                'fastfood',
                'lodging',
                'tourist attraction',
            }
            for item in elements:
                tags = item.get('tags') or {}
                name = tags.get('name') or ''
                if query_lower and query_lower not in generic_queries:
                    searchable = ' '.join(
                        [
                            name,
                            tags.get('brand', ''),
                            tags.get('amenity', ''),
                            tags.get('tourism', ''),
                            tags.get('cuisine', ''),
                            tags.get('addr:street', ''),
                            tags.get('addr:city', ''),
                        ]
                    ).lower()
                    if searchable and query_lower not in searchable:
                        continue

                lat = item.get('lat')
                lon = item.get('lon')
                if lat is None or lon is None:
                    center = item.get('center') or {}
                    lat = center.get('lat')
                    lon = center.get('lon')
                if lat is None or lon is None:
                    continue

                element_type = item.get('type', 'node')
                element_id = item.get('id')
                external_id = f'osm:{element_type}/{element_id}'

                address = tags.get('addr:full') or tags.get('addr:street') or tags.get('addr:city') or ''
                title = name or tags.get('brand') or query or 'Lieu'

                records.append({
                    'source': 'google_maps',
                    'external_id': external_id,
                    'title': title,
                    'text': address,
                    'author': 'osm_overpass',
                    'metadata': {
                        'provider': 'openstreetmap',
                        'query': query,
                        'place_type': place_type,
                        'latitude': lat,
                        'longitude': lon,
                        'input_latitude': latitude,
                        'input_longitude': longitude,
                        'maps_url': f'https://www.openstreetmap.org/{element_type}/{element_id}',
                        'fallback_reason': fallback_reason,
                    },
                })

                if len(records) >= capped_results:
                    break

            return {
                'success': True,
                'provider': 'openstreetmap',
                'fallback_reason': fallback_reason,
                'records': records,
                'count': len(records),
                'processing_time': time.time() - start_time,
                'warning': 'Collecte via OpenStreetMap (fallback)',
            }
        except Exception as exc:
            return {
                'success': False,
                'error': f'{fallback_reason} | fallback OSM indisponible: {exc}',
                'records': [],
                'processing_time': time.time() - start_time,
            }

    def collect_google_maps(self, query, latitude, longitude, radius=2000, place_type='restaurant', max_results=5):
        start_time = time.time()

        if not self.google_maps_api_key:
            return self._collect_osm_places(
                query=query,
                latitude=latitude,
                longitude=longitude,
                radius=radius,
                place_type=place_type,
                max_results=max_results,
                start_time=start_time,
                fallback_reason='GOOGLE_MAPS_API_KEY non configuree',
            )

        url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        params = {
            'key': self.google_maps_api_key,
            'location': f'{latitude},{longitude}',
            'radius': int(radius),
            'keyword': query,
            'type': place_type,
        }

        try:
            response = requests.get(url, params=params, timeout=30)
            payload = response.json()

            if response.status_code >= 400:
                return self._collect_osm_places(
                    query=query,
                    latitude=latitude,
                    longitude=longitude,
                    radius=radius,
                    place_type=place_type,
                    max_results=max_results,
                    start_time=start_time,
                    fallback_reason=f'Erreur HTTP Google Places: {response.status_code}',
                )

            status = payload.get('status', 'UNKNOWN_ERROR')
            if status not in ('OK', 'ZERO_RESULTS'):
                return self._collect_osm_places(
                    query=query,
                    latitude=latitude,
                    longitude=longitude,
                    radius=radius,
                    place_type=place_type,
                    max_results=max_results,
                    start_time=start_time,
                    fallback_reason=payload.get('error_message') or f'Google Places status: {status}',
                )

            records = []
            capped_results = min(int(max_results or 5), 5)
            for item in payload.get('results', [])[:capped_results]:
                place_id = item.get('place_id')
                if not place_id:
                    continue

                geometry = item.get('geometry') or {}
                location = geometry.get('location') or {}

                photo_reference = ((item.get('photos') or [{}])[0] or {}).get('photo_reference')

                metadata = {
                    'query': query,
                    'place_type': place_type,
                    'latitude': location.get('lat'),
                    'longitude': location.get('lng'),
                    'input_latitude': latitude,
                    'input_longitude': longitude,
                    'rating': item.get('rating'),
                    'user_ratings_total': self._safe_int(item.get('user_ratings_total')),
                    'price_level': item.get('price_level'),
                    'open_now': ((item.get('opening_hours') or {}).get('open_now')),
                    'types': item.get('types', []),
                    'business_status': item.get('business_status'),
                    'vicinity': item.get('vicinity', ''),
                    'formatted_address': item.get('formatted_address', ''),
                    'maps_url': f'https://www.google.com/maps/place/?q=place_id:{place_id}',
                    'photo_reference': photo_reference,
                }

                records.append({
                    'source': 'google_maps',
                    'external_id': place_id,
                    'title': item.get('name', ''),
                    'text': item.get('vicinity', '') or item.get('formatted_address', ''),
                    'author': 'google_places',
                    'metadata': metadata,
                })

            return {
                'success': True,
                'provider': 'google_places',
                'records': records,
                'count': len(records),
                'processing_time': time.time() - start_time,
            }
        except Exception as exc:
            return {
                'success': False,
                'error': str(exc),
                'records': [],
                'processing_time': time.time() - start_time,
            }

data_collection_service = DataCollectionService()
