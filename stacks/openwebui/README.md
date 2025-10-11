# OpenWebUI with LiteLLM, Ollama, and PostgreSQL

This setup includes:

- **Open WebUI**: Web interface for interacting with LLMs
- **LiteLLM**: Proxy server for multiple external LLM providers (OpenAI, Anthropic, xAI)
- **Ollama**: Local LLM server for running models on your hardware
- **PostgreSQL**: Database for storing LiteLLM data, logs, and configurations

## Features

- **Dual LLM Support**:
  - External APIs via LiteLLM (OpenAI, Anthropic, xAI)
  - Local models via Ollama (Llama, Mistral, CodeLlama, etc.)
- **Database Persistence**: All LiteLLM data is stored in PostgreSQL
- **Request Logging**: Track all API requests and responses
- **Rate Limiting**: Built-in budget and rate limiting
- **Model Management**: Store model configurations in database
- **Local Privacy**: Run models locally with Ollama for sensitive data

## Quick Start

1. Copy the environment template:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your API keys:

   - `LITELLM_API_KEY`: Your LiteLLM master key
   - `OPENAI_API_KEY`: Your OpenAI API key
   - `ANTHROPIC_API_KEY`: Your Anthropic API key
   - `POSTGRES_PASSWORD`: Database password (default: litellm_password)

3. Start the services:

   ```bash
   docker-compose up -d
   ```

4. Set up Ollama models (optional):

   ```bash
   chmod +x setup-ollama-models.sh
   ./setup-ollama-models.sh
   ```

5. Access the applications:

   - Open WebUI: <http://localhost:3000>
   - LiteLLM API: <http://localhost:4000>
   - Ollama API: <http://localhost:11434>
   - PostgreSQL: localhost:5432

## Architecture

### LiteLLM (External APIs)

- Handles external API providers (OpenAI, Anthropic, xAI)
- Routes through PostgreSQL for logging and rate limiting
- Accessible at <http://localhost:4000/v1>

### Ollama (Local Models)

- Runs models locally on your hardware
- Direct connection to OpenWebUI (separate from LiteLLM)
- Accessible at <http://localhost:11434>
- Supports GPU acceleration (uncomment GPU config in docker-compose.yml)

### OpenWebUI Integration

- Automatically detects both LiteLLM and Ollama services
- Provides unified interface for all models
- External models appear with API provider names
- Local models appear with Ollama prefix

## Database Features

The PostgreSQL database provides:

- **Persistent storage** for all LiteLLM configurations
- **Request/response logging** for debugging and analytics
- **User management** and authentication data
- **Rate limiting** and budget tracking
- **Model usage statistics**

## Configuration

The LiteLLM configuration (`litellm_config.yaml`) includes:

- Database connection settings
- Model definitions
- Rate limiting rules
- Logging callbacks
- Caching configuration

## Monitoring

To view database logs:

```bash
docker compose logs postgres
```

To view LiteLLM logs:

```bash
docker compose logs litellm
```

## Database Management

Connect to PostgreSQL:

```bash
docker exec -it litellm-postgres psql -U litellm -d litellm
```

Backup database:

```bash
docker exec litellm-postgres pg_dump -U litellm litellm > backup.sql
```

Restore database:

```bash
docker exec -i litellm-postgres psql -U litellm -d litellm < backup.sql
```