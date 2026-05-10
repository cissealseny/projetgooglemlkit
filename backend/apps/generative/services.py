import time
import logging
from django.conf import settings

logger = logging.getLogger(__name__)


class GenerativeService:

    SYSTEM_PROMPT = """Tu es un assistant IA intelligent, amical et serviable.
Réponds naturellement et dans la langue de l'utilisateur.
Sois clair, précis et conversationnel.
"""

    def __init__(self):
        self.ollama_host = getattr(settings, 'OLLAMA_HOST', 'http://localhost:11434')
        self.gemini_api_key = getattr(settings, 'GEMINI_API_KEY', '')
        self.openai_api_key = getattr(settings, 'OPENAI_API_KEY', '')

    # -------------------------------------------------
    # CHAT ROUTER
    # -------------------------------------------------
    def chat(self, messages, model='ollama:mistral', temperature=0.7, max_tokens=1024):
        start_time = time.time()

        try:

            if model.startswith('ollama:'):
                ollama_model = model.replace('ollama:', '')
                return self._ollama_chat(messages, ollama_model, temperature, max_tokens)

            elif model.startswith('hf:'):
                hf_model = model.replace('hf:', '')
                return self._huggingface_chat(messages, hf_model, temperature, max_tokens)

            elif model.startswith('gemini:'):
                gemini_model = model.replace('gemini:', '')
                return self._gemini_chat(messages, gemini_model, temperature, max_tokens)

            elif model.startswith('gpt:'):
                gpt_model = model.replace('gpt:', '')
                return self._openai_chat(messages, gpt_model, temperature, max_tokens)

            else:
                raise Exception("Unsupported model provider")

        except Exception as e:
            logger.error(f"Chat error: {str(e)}")

            # If local Ollama fails, transparently fallback to Gemini when configured.
            if model.startswith('ollama:') and self.gemini_api_key:
                try:
                    fallback_result = self._gemini_chat(
                        messages,
                        'gemini-2.0-flash',
                        temperature,
                        max_tokens,
                    )
                    fallback_result['fallback_from'] = model
                    fallback_result['fallback_notice'] = (
                        'Ollama indisponible, reponse generee via Gemini 2.0 Flash.'
                    )
                    return fallback_result
                except Exception as fallback_error:
                    logger.error(f"Gemini fallback failed: {str(fallback_error)}")

            return {
                "success": False,
                "error": str(e),
                "processing_time": time.time() - start_time
            }

    # -------------------------------------------------
    # OLLAMA
    # -------------------------------------------------
    def _ollama_chat(self, messages, model, temperature, max_tokens):

        start_time = time.time()

        try:
            import ollama

            messages_with_system = list(messages)

            if not any(m.get("role") == "system" for m in messages_with_system):
                messages_with_system.insert(0, {
                    "role": "system",
                    "content": self.SYSTEM_PROMPT
                })

            response = ollama.chat(
                model=model,
                messages=messages_with_system,
                options={
                    "temperature": temperature,
                    "num_predict": max_tokens
                }
            )

            return {
                "success": True,
                "response": response["message"]["content"],
                "model": f"ollama:{model}",
                "tokens_used": 0,
                "processing_time": time.time() - start_time
            }

        except Exception as e:
            raise Exception(f"Ollama error: {str(e)}")

    # -------------------------------------------------
    # HUGGINGFACE
    # -------------------------------------------------
    def _huggingface_chat(self, messages, model, temperature, max_tokens):

        start_time = time.time()

        try:
            from transformers import pipeline

            prompt = "\n".join([f"{m['role'].upper()}: {m['content']}" for m in messages])
            prompt += "\nASSISTANT:"

            generator = pipeline(
                "text-generation",
                model=model,
                max_new_tokens=max_tokens,
                temperature=temperature,
                do_sample=True
            )

            output = generator(prompt)[0]["generated_text"]
            response_text = output.split("ASSISTANT:")[-1].strip()

            return {
                "success": True,
                "response": response_text,
                "model": f"hf:{model}",
                "tokens_used": 0,
                "processing_time": time.time() - start_time
            }

        except Exception as e:
            raise Exception(f"HuggingFace error: {str(e)}")

    # -------------------------------------------------
    # GEMINI
    # -------------------------------------------------
    def _gemini_chat(self, messages, model, temperature, max_tokens):

        start_time = time.time()

        try:
            import google.generativeai as genai

            genai.configure(api_key=self.gemini_api_key)

            gemini_model = genai.GenerativeModel(
                model_name=model,
                generation_config=genai.types.GenerationConfig(
                    temperature=temperature,
                    max_output_tokens=max_tokens,
                )
            )

            history = []
            for msg in messages[:-1]:
                role = "user" if msg["role"] == "user" else "model"
                history.append({
                    "role": role,
                    "parts": [msg["content"]]
                })

            chat_session = gemini_model.start_chat(history=history)

            response = chat_session.send_message(messages[-1]["content"])

            return {
                "success": True,
                "response": response.text,
                "model": f"gemini:{model}",
                "tokens_used": 0,
                "processing_time": time.time() - start_time
            }

        except Exception as e:
            raise Exception(f"Gemini error: {str(e)}")

    # -------------------------------------------------
    # OPENAI GPT
    # -------------------------------------------------
    def _openai_chat(self, messages, model, temperature, max_tokens):

        start_time = time.time()

        try:
            from openai import OpenAI

            client = OpenAI(api_key=self.openai_api_key)

            response = client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=temperature,
                max_tokens=max_tokens
            )

            return {
                "success": True,
                "response": response.choices[0].message.content,
                "model": f"gpt:{model}",
                "tokens_used": response.usage.total_tokens,
                "processing_time": time.time() - start_time
            }

        except Exception as e:
            raise Exception(f"OpenAI error: {str(e)}")

    # -------------------------------------------------
    # HELPER FUNCTIONS
    # -------------------------------------------------
    def generate_text(self, prompt, model="ollama:mistral", temperature=0.7, max_tokens=1024):

        messages = [
            {"role": "user", "content": prompt}
        ]

        return self.chat(messages, model, temperature, max_tokens)

    def generate_code(self, prompt, language="python", model="ollama:mistral"):

        code_prompt = f"""
Generate {language} code for the following task:
{prompt}

Only output the code with comments.
"""

        return self.generate_text(code_prompt, model, temperature=0.3, max_tokens=2048)

    def generate_embedding(self, text, model="hf:all-MiniLM-L6-v2"):

        start_time = time.time()

        try:
            from sentence_transformers import SentenceTransformer

            hf_model = model.replace("hf:", "")
            st_model = SentenceTransformer(hf_model)

            embedding = st_model.encode(text).tolist()

            return {
                "success": True,
                "embedding": embedding,
                "model": hf_model,
                "dimensions": len(embedding),
                "processing_time": time.time() - start_time
            }

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "processing_time": time.time() - start_time
            }


generative_service = GenerativeService()