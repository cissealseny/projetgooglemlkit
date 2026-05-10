"""
NLP Services
Provides natural language processing capabilities
"""

import time
import os
import re
import unicodedata
from django.conf import settings


class NLPService:
    """Service class for NLP operations"""
    
    def __init__(self):
        self.use_google_cloud = bool(settings.GOOGLE_APPLICATION_CREDENTIALS)
        self.use_transformers = True  # Use HuggingFace Transformers as fallback
        self.default_provider = os.getenv('NLP_PROVIDER', 'auto').strip().lower() or 'auto'
        self._pipeline_cache = {}

    def _resolve_provider(self, provider):
        selected = (provider or self.default_provider or 'auto').strip().lower()
        if selected not in {'auto', 'google', 'huggingface'}:
            selected = 'auto'
        return selected

    def _should_use_google(self, provider):
        selected = self._resolve_provider(provider)
        if selected == 'google':
            return self.use_google_cloud
        if selected == 'huggingface':
            return False
        return self.use_google_cloud

    def _get_pipeline(self, task, model, **kwargs):
        try:
            from transformers import pipeline
        except Exception:
            return None

        cache_key = (task, model, tuple(sorted(kwargs.items())))
        cached = self._pipeline_cache.get(cache_key)
        if cached is not None:
            return cached

        created = pipeline(task, model=model, **kwargs)
        self._pipeline_cache[cache_key] = created
        return created
    
    def analyze_sentiment(self, text, provider='auto'):
        """
        Analyze sentiment of the given text
        Returns sentiment score and magnitude
        """
        start_time = time.time()
        
        try:
            resolved = self._resolve_provider(provider)
            if self._should_use_google(resolved):
                result = self._google_sentiment(text)
                result['provider_used'] = 'google'
            else:
                result = self._transformers_sentiment(text)
                result['provider_used'] = 'huggingface'
            result['provider_requested'] = resolved
            return result
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'provider_requested': self._resolve_provider(provider),
                'processing_time': time.time() - start_time
            }
    
    def _google_sentiment(self, text):
        """Sentiment analysis using Google Cloud Natural Language API"""
        from google.cloud import language_v1
        
        start_time = time.time()
        client = language_v1.LanguageServiceClient()
        
        document = language_v1.Document(
            content=text,
            type_=language_v1.Document.Type.PLAIN_TEXT
        )
        
        response = client.analyze_sentiment(document=document)
        sentiment = response.document_sentiment
        
        return {
            'success': True,
            'score': sentiment.score,  # -1.0 to 1.0
            'magnitude': sentiment.magnitude,  # 0 to infinity
            'sentiment': self._score_to_label(sentiment.score),
            'sentences': [
                {
                    'text': sentence.text.content,
                    'score': sentence.sentiment.score,
                    'magnitude': sentence.sentiment.magnitude
                }
                for sentence in response.sentences
            ],
            'processing_time': time.time() - start_time
        }
    
    def _transformers_sentiment(self, text):
        """Sentiment analysis using HuggingFace Transformers"""
        start_time = time.time()
        
        try:
            classifier = self._get_pipeline(
                'sentiment-analysis',
                'nlptown/bert-base-multilingual-uncased-sentiment',
            )
            if classifier is None:
                raise RuntimeError('HuggingFace pipeline indisponible')
            result = classifier(text[:512])[0]  # Limit to 512 tokens
            
            # Convert 1-5 star rating to -1 to 1 score
            stars = int(result['label'].split()[0])
            score = (stars - 3) / 2  # 1 star = -1, 5 stars = 1
            
            return {
                'success': True,
                'score': score,
                'magnitude': result['score'],
                'sentiment': self._score_to_label(score),
                'raw_label': result['label'],
                'confidence': result['score'],
                'processing_time': time.time() - start_time
            }
        except Exception as e:
            return {
                'success': True,
                'score': 0,
                'magnitude': 0,
                'sentiment': 'neutral',
                'note': 'Transformers not configured, using placeholder',
                'processing_time': time.time() - start_time
            }
    
    def _score_to_label(self, score):
        """Convert score to sentiment label"""
        if score >= 0.25:
            return 'positive'
        elif score <= -0.25:
            return 'negative'
        else:
            return 'neutral'
    
    def extract_entities(self, text, provider='auto'):
        """
        Extract named entities from the given text
        Returns list of entities with types
        """
        start_time = time.time()
        
        try:
            resolved = self._resolve_provider(provider)
            if self._should_use_google(resolved):
                result = self._google_entities(text)
                result['provider_used'] = 'google'
            else:
                result = self._transformers_entities(text)
                result['provider_used'] = 'huggingface'
            result['provider_requested'] = resolved
            return result
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'provider_requested': self._resolve_provider(provider),
                'processing_time': time.time() - start_time
            }
    
    def _google_entities(self, text):
        """Entity extraction using Google Cloud Natural Language API"""
        from google.cloud import language_v1
        
        start_time = time.time()
        client = language_v1.LanguageServiceClient()
        
        document = language_v1.Document(
            content=text,
            type_=language_v1.Document.Type.PLAIN_TEXT
        )
        
        response = client.analyze_entities(document=document)
        
        entity_types = {
            0: 'UNKNOWN',
            1: 'PERSON',
            2: 'LOCATION',
            3: 'ORGANIZATION',
            4: 'EVENT',
            5: 'WORK_OF_ART',
            6: 'CONSUMER_GOOD',
            7: 'OTHER',
            9: 'PHONE_NUMBER',
            10: 'ADDRESS',
            11: 'DATE',
            12: 'NUMBER',
            13: 'PRICE'
        }
        
        return {
            'success': True,
            'entities': [
                {
                    'name': entity.name,
                    'type': entity_types.get(entity.type_, 'UNKNOWN'),
                    'salience': entity.salience,
                    'mentions': len(entity.mentions)
                }
                for entity in response.entities
            ],
            'count': len(response.entities),
            'processing_time': time.time() - start_time
        }
    
    def _transformers_entities(self, text):
        """Entity extraction using HuggingFace Transformers"""
        start_time = time.time()
        
        try:
            ner = self._get_pipeline(
                'ner',
                'dbmdz/bert-large-cased-finetuned-conll03-english',
                aggregation_strategy='simple',
            )
            if ner is None:
                raise RuntimeError('HuggingFace pipeline indisponible')
            results = ner(text[:512])
            
            return {
                'success': True,
                'entities': [
                    {
                        'name': entity['word'],
                        'type': entity['entity_group'],
                        'confidence': entity['score'],
                        'start': entity['start'],
                        'end': entity['end']
                    }
                    for entity in results
                ],
                'count': len(results),
                'processing_time': time.time() - start_time
            }
        except Exception as e:
            return {
                'success': True,
                'entities': [],
                'count': 0,
                'note': 'Transformers not configured',
                'processing_time': time.time() - start_time
            }
    
    def detect_language(self, text):
        """
        Detect the language of the given text
        Returns detected language with confidence
        """
        start_time = time.time()
        
        try:
            # Simple language detection using langdetect
            from langdetect import detect, detect_langs
            
            detected = detect(text)
            probabilities = detect_langs(text)
            
            return {
                'success': True,
                'language': detected,
                'probabilities': [
                    {'language': str(p).split(':')[0], 'probability': float(str(p).split(':')[1])}
                    for p in probabilities
                ],
                'processing_time': time.time() - start_time
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'processing_time': time.time() - start_time
            }
    
    def translate_text(self, text, source_language='auto', target_language='en', provider='auto'):
        """
        Translate text from source to target language
        """
        start_time = time.time()
        
        try:
            resolved = self._resolve_provider(provider)
            if self._should_use_google(resolved):
                result = self._google_translate(text, source_language, target_language)
                result['provider_used'] = 'google'
            else:
                result = self._transformers_translate(text, source_language, target_language)
                result['provider_used'] = 'huggingface'
            result['provider_requested'] = resolved
            return result
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'provider_requested': self._resolve_provider(provider),
                'processing_time': time.time() - start_time
            }
    
    def _google_translate(self, text, source_language, target_language):
        """Translation using Google Cloud Translation API"""
        from google.cloud import translate_v2 as translate
        
        start_time = time.time()
        client = translate.Client()
        
        if source_language == 'auto':
            result = client.translate(text, target_language=target_language)
        else:
            result = client.translate(
                text, 
                source_language=source_language,
                target_language=target_language
            )
        
        return {
            'success': True,
            'original_text': text,
            'translated_text': result['translatedText'],
            'detected_source_language': result.get('detectedSourceLanguage', source_language),
            'target_language': target_language,
            'processing_time': time.time() - start_time
        }
    
    def _transformers_translate(self, text, source_language, target_language):
        """Translation using HuggingFace Transformers"""
        start_time = time.time()
        
        try:
            model_name = f'Helsinki-NLP/opus-mt-{source_language}-{target_language}'
            translator = self._get_pipeline('translation', model_name)
            if translator is None:
                raise RuntimeError('HuggingFace pipeline indisponible')
            result = translator(text[:512])[0]
            
            return {
                'success': True,
                'original_text': text,
                'translated_text': result['translation_text'],
                'source_language': source_language,
                'target_language': target_language,
                'processing_time': time.time() - start_time
            }
        except Exception as e:
            return {
                'success': True,
                'original_text': text,
                'translated_text': '[Translation requires model configuration]',
                'note': f'Model not available: {str(e)}',
                'processing_time': time.time() - start_time
            }
    
    def summarize_text(self, text, max_length=150, min_length=50, provider='auto'):
        """
        Summarize the given text
        """
        start_time = time.time()
        
        resolved = self._resolve_provider(provider)
        if self._should_use_google(resolved):
            return {
                'success': True,
                'original_text': text,
                'summary': text[:min_length] + ('...' if len(text) > min_length else ''),
                'original_length': len(text),
                'summary_length': min(len(text), min_length + 3),
                'compression_ratio': (min(len(text), min_length + 3) / len(text)) if len(text) else 1,
                'provider_used': 'google',
                'provider_requested': resolved,
                'note': 'Summarization Google non configuree dans ce backend, resume fallback applique.',
                'processing_time': time.time() - start_time
            }

        try:
            summarizer = self._get_pipeline('summarization', 'facebook/bart-large-cnn')
            if summarizer is None:
                raise RuntimeError('HuggingFace pipeline indisponible')
            result = summarizer(text, max_length=max_length, min_length=min_length, do_sample=False)[0]
            
            return {
                'success': True,
                'original_text': text,
                'summary': result['summary_text'],
                'original_length': len(text),
                'summary_length': len(result['summary_text']),
                'compression_ratio': len(result['summary_text']) / len(text),
                'provider_used': 'huggingface',
                'provider_requested': resolved,
                'processing_time': time.time() - start_time
            }
        except Exception as e:
            return {
                'success': True,
                'original_text': text,
                'summary': text[:min_length] + '...',
                'provider_used': 'huggingface',
                'provider_requested': resolved,
                'note': 'Summarization model not available',
                'processing_time': time.time() - start_time
            }
    
    def classify_text(self, text, categories=None, provider='auto'):
        """
        Classify text into categories
        """
        start_time = time.time()
        
        resolved = self._resolve_provider(provider)
        if self._should_use_google(resolved):
            return {
                'success': True,
                'text': text,
                'label': 'UNKNOWN',
                'provider_used': 'google',
                'provider_requested': resolved,
                'note': 'Classification Google non configuree dans ce backend, utilisez provider=huggingface.',
                'processing_time': time.time() - start_time
            }

        try:
            if categories:
                # Fast deterministic classification to avoid long zero-shot timeouts.
                fast = self._classify_with_categories_fast(text, categories)
                return {
                    'success': True,
                    'text': text,
                    'categories': fast['categories'],
                    'top_category': fast['top_category'],
                    'confidence': fast['confidence'],
                    'provider_used': 'huggingface-heuristic',
                    'provider_requested': resolved,
                    'note': 'Mode rapide active pour eviter les timeouts du zero-shot.',
                    'processing_time': time.time() - start_time
                }
            else:
                # Default topic classification
                classifier = self._get_pipeline(
                    'text-classification',
                    'distilbert-base-uncased-finetuned-sst-2-english',
                )
                if classifier is None:
                    raise RuntimeError('HuggingFace pipeline indisponible')
                result = classifier(text[:512])[0]
                
                return {
                    'success': True,
                    'text': text,
                    'label': result['label'],
                    'confidence': result['score'],
                    'provider_used': 'huggingface',
                    'provider_requested': resolved,
                    'processing_time': time.time() - start_time
                }
        except Exception as e:
            return {
                'success': True,
                'text': text,
                'label': 'UNKNOWN',
                'provider_used': 'huggingface',
                'provider_requested': resolved,
                'note': 'Classification model not available',
                'processing_time': time.time() - start_time
            }

    def _classify_with_categories_fast(self, text, categories):
        text_norm = self._normalize_text(text)
        text_tokens = set([t for t in text_norm.split() if len(t) > 2])

        scored = []
        for raw_category in categories:
            category = str(raw_category or '').strip()
            category_norm = self._normalize_text(category)
            cat_tokens = set([t for t in category_norm.split() if len(t) > 2])

            overlap = len(text_tokens.intersection(cat_tokens))
            substring_bonus = 1.0 if category_norm and category_norm in text_norm else 0.0
            score = overlap + substring_bonus
            scored.append({'label': category, 'raw_score': float(score)})

        max_raw = max([item['raw_score'] for item in scored], default=0.0)
        if max_raw <= 0:
            # Uniform fallback when no lexical overlap is found.
            uniform = 1.0 / max(len(scored), 1)
            categories_out = [
                {'label': item['label'], 'score': uniform}
                for item in scored
            ]
        else:
            total = sum(item['raw_score'] for item in scored)
            categories_out = [
                {'label': item['label'], 'score': (item['raw_score'] / total) if total else 0.0}
                for item in scored
            ]

        categories_out.sort(key=lambda item: item['score'], reverse=True)
        top = categories_out[0] if categories_out else {'label': 'UNKNOWN', 'score': 0.0}

        return {
            'categories': categories_out,
            'top_category': top['label'],
            'confidence': top['score'],
        }

    def _normalize_text(self, value):
        lowered = (value or '').lower()
        normalized = unicodedata.normalize('NFD', lowered)
        no_accents = ''.join(ch for ch in normalized if unicodedata.category(ch) != 'Mn')
        return re.sub(r'[^a-z0-9\s]+', ' ', no_accents).strip()


# Singleton instance
nlp_service = NLPService()
