# DietMOA Agent - Makefile
# Orchestrates build, deployment, and testing processes

.PHONY: help setup build start stop restart clean test init-db load-data logs

# Default target
help:
	@echo "DietMOA Agent - Available Commands:"
	@echo "  make setup       - Install dependencies and prepare environment"
	@echo "  make build       - Build Docker containers"
	@echo "  make start       - Start all services"
	@echo "  make stop        - Stop all services"
	@echo "  make restart     - Restart all services"
	@echo "  make clean       - Clean up containers and volumes"
	@echo "  make test        - Run all tests"
	@echo "  make init-db     - Initialize databases"
	@echo "  make load-data   - Load initial biochemical data"
	@echo "  make logs        - Show service logs"
	@echo "  make dev         - Start in development mode"
	@echo "  make prod        - Start in production mode"

# Setup environment
setup:
	@echo "🔧 Setting up environment..."
	@cp -n .env.example .env || true
	@pip install -r requirements.txt
	@npm install
	@echo "✅ Environment setup complete"

# Build containers
build:
	@echo "🏗️ Building containers..."
	@docker-compose build --parallel
	@echo "✅ Build complete"

# Start services
start:
	@echo "🚀 Starting services..."
	@docker-compose up -d
	@echo "⏳ Waiting for services to be healthy..."
	@sleep 10
	@./scripts/health_check.sh
	@echo "✅ All services running"

# Stop services
stop:
	@echo "🛑 Stopping services..."
	@docker-compose down
	@echo "✅ Services stopped"

# Restart services
restart: stop start

# Clean up everything
clean:
	@echo "🧹 Cleaning up..."
	@docker-compose down -v --remove-orphans
	@rm -rf data/neo4j/*
	@rm -rf data/mindsdb/*
	@rm -rf data/mem0/*
	@echo "✅ Cleanup complete"

# Initialize databases
init-db:
	@echo "🗄️ Initializing databases..."
	@./scripts/setup_databases.sh
	@python scripts/create_schema.py
	@echo "✅ Databases initialized"

# Load initial data
load-data:
	@echo "📊 Loading dietary and nutritional data..."
	@python scripts/load_pathways.py
	@python scripts/index_compounds.py
	@python scripts/import_proteins.py
	@echo "✅ Data loading complete"

# Run all tests
test: test-unit test-integration

# Run unit tests
test-unit:
	@echo "🧪 Running unit tests..."
	@pytest tests/unit/ -v --cov=mcp_server --cov=agents --cov=graph
	@echo "✅ Unit tests complete"

# Run integration tests
test-integration:
	@echo "🔗 Running integration tests..."
	@pytest tests/integration/ -v
	@echo "✅ Integration tests complete"

# Run end-to-end tests
test-e2e:
	@echo "🎯 Running end-to-end tests..."
	@pytest tests/e2e/ -v --slow
	@echo "✅ E2E tests complete"

# Show logs
logs:
	@docker-compose logs -f --tail=100

# Development mode
dev:
	@echo "💻 Starting in development mode..."
	@export ENVIRONMENT=development && docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Production mode
prod:
	@echo "🏭 Starting in production mode..."
	@export ENVIRONMENT=production && docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# MCP Server specific commands
mcp-start:
	@echo "🤖 Starting MCP server..."
	@npm run start:mcp

mcp-dev:
	@echo "🔧 Starting MCP server in dev mode..."
	@npm run dev:mcp

mcp-test:
	@echo "🧪 Testing MCP server..."
	@npm test

# Database management
db-backup:
	@echo "💾 Backing up databases..."
	@./scripts/backup_databases.sh
	@echo "✅ Backup complete"

db-restore:
	@echo "♻️ Restoring databases..."
	@./scripts/restore_databases.sh
	@echo "✅ Restore complete"

# Graph operations
graph-stats:
	@echo "📊 Graph statistics..."
	@python scripts/graph_statistics.py

graph-visualize:
	@echo "🎨 Generating graph visualization..."
	@python scripts/visualize_graph.py

# Memory operations
memory-clear:
	@echo "🧹 Clearing memory store..."
	@python scripts/clear_memory.py
	@echo "✅ Memory cleared"

memory-export:
	@echo "📤 Exporting memory..."
	@python scripts/export_memory.py
	@echo "✅ Memory exported"

# Knowledge base operations
kb-reindex:
	@echo "🔄 Reindexing knowledge base..."
	@python scripts/reindex_kb.py
	@echo "✅ Reindexing complete"

kb-stats:
	@echo "📊 Knowledge base statistics..."
	@python scripts/kb_statistics.py

# Monitoring
monitor:
	@echo "📈 Starting monitoring dashboard..."
	@docker-compose -f docker-compose.monitoring.yml up -d
	@echo "Dashboard available at http://localhost:3000"

# Performance testing
perf-test:
	@echo "⚡ Running performance tests..."
	@locust -f tests/performance/locustfile.py --host=http://localhost:8080

# Security scanning
security-scan:
	@echo "🔒 Running security scan..."
	@bandit -r mcp_server/ agents/ -f json -o security_report.json
	@safety check --json
	@echo "✅ Security scan complete"

# Code quality
lint:
	@echo "🎨 Running linters..."
	@flake8 mcp_server/ agents/ graph/ memory/
	@black --check mcp_server/ agents/ graph/ memory/
	@mypy mcp_server/ agents/
	@echo "✅ Linting complete"

format:
	@echo "🎨 Formatting code..."
	@black mcp_server/ agents/ graph/ memory/
	@isort mcp_server/ agents/ graph/ memory/
	@echo "✅ Formatting complete"

# Documentation
docs:
	@echo "📚 Building documentation..."
	@sphinx-build -b html docs/ docs/_build/
	@echo "✅ Documentation available at docs/_build/index.html"

# Version management
version:
	@echo "📌 Current version:"
	@cat VERSION

bump-version:
	@echo "⬆️ Bumping version..."
	@bumpversion patch
	@echo "✅ Version bumped"

# CI/CD helpers
ci-test:
	@make lint
	@make test-unit
	@make test-integration
	@make security-scan

ci-deploy:
	@echo "🚀 Deploying to production..."
	@./scripts/deploy.sh
	@echo "✅ Deployment complete"
