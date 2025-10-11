#!/bin/bash

# Setup script for Ollama models (October 2025)
# This script pulls the best recommended models for local use
# Note: Ollama models are separate from LiteLLM and connect directly to OpenWebUI

echo "======================================"
echo "Ollama Model Setup (October 2025)"
echo "======================================"
echo ""

# Check if Ollama container is running
if ! docker ps | grep -q ollama; then
    echo "Error: Ollama container is not running."
    echo "Please start with 'docker compose up -d ollama' first."
    exit 1
fi

echo "This script will install recommended models in priority order:"
echo ""
echo "SMALL MODELS (< 5GB):"
echo "  1. qwen2.5:3b        (~2GB)   - Best small general model"
echo ""
echo "MEDIUM MODELS (5-10GB):"
echo "  2. qwen2.5-coder:7b  (~4.7GB) - Best coding model"
echo "  3. deepseek-r1:7b    (~4.1GB) - Reasoning capability"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "======================================"
echo "Installing Small Models (< 5GB)"
echo "======================================"
echo ""

echo "[1/3] Pulling qwen2.5:3b - Best small general model (~2GB)..."
docker exec ollama ollama pull qwen2.5:3b

echo ""
echo "======================================"
echo "Installing Medium Models (5-10GB)"
echo "======================================"
echo ""

echo "[2/3] Pulling qwen2.5-coder:7b - Best coding model (~4.7GB)..."
docker exec ollama ollama pull qwen2.5-coder:7b

echo ""
echo "[3/3] Pulling deepseek-r1:7b - Reasoning capability (~4.1GB)..."
docker exec ollama ollama pull deepseek-r1:7b

echo ""
echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "Available Ollama models:"
docker exec ollama ollama list

echo ""
echo "MODEL RECOMMENDATIONS BY USE CASE:"
echo ""
echo "  General tasks:        qwen2.5:3b"
echo "  Coding/development:   qwen2.5-coder:7b"
echo "  Reasoning tasks:      deepseek-r1:7b"
echo ""
echo "ARCHITECTURE:"
echo "  - Ollama models available directly in OpenWebUI (separate from LiteLLM)"
echo "  - LiteLLM handles external APIs (OpenAI, Anthropic, xAI) at http://localhost:4000/v1"
echo "  - Ollama handles local models at http://localhost:11434"
echo "  - OpenWebUI connects to both services automatically"
echo ""
echo "Access your setup at: http://localhost:3000"
echo ""
