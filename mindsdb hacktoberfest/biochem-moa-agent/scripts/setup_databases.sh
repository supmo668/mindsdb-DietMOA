#!/bin/bash

# DietMOA Agent - Database Setup Script
# =====================================
# Initializes all required databases with schemas, indexes, and initial data
#
# Databases configured:
# - Neo4j: Graph database for dietary and nutritional networks
# - PostgreSQL: MindsDB backend storage
# - Qdrant: Vector database for memory embeddings
# - Redis: Cache layer for API responses
#
# Usage: ./setup_databases.sh [environment]
# Environment: development (default), staging, production

set -e  # Exit on error
set -u  # Exit on undefined variable

# Configuration
ENVIRONMENT=${1:-development}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load environment variables
if [ -f "$PROJECT_ROOT/.env.$ENVIRONMENT" ]; then
    export $(cat "$PROJECT_ROOT/.env.$ENVIRONMENT" | grep -v '^#' | xargs)
else
    log_warn "Environment file .env.$ENVIRONMENT not found, using defaults"
fi

# Neo4j Setup
setup_neo4j() {
    log_info "Setting up Neo4j graph database..."
    
    # Wait for Neo4j to be ready
    until curl -s http://localhost:7474 > /dev/null; do
        log_info "Waiting for Neo4j to start..."
        sleep 5
    done
    
    # Create constraints and indexes
    cypher-shell -u neo4j -p "${NEO4J_PASSWORD:-password123}" <<EOF
// Create constraints for unique identifiers
CREATE CONSTRAINT compound_smiles IF NOT EXISTS
FOR (c:Compound) REQUIRE c.smiles IS UNIQUE;

CREATE CONSTRAINT protein_uniprot IF NOT EXISTS
FOR (p:Protein) REQUIRE p.uniprot_id IS UNIQUE;

CREATE CONSTRAINT pathway_kegg IF NOT EXISTS
FOR (pw:Pathway) REQUIRE pw.kegg_id IS UNIQUE;

// Create indexes for common queries
CREATE INDEX compound_name IF NOT EXISTS
FOR (c:Compound) ON (c.name);

CREATE INDEX protein_name IF NOT EXISTS
FOR (p:Protein) ON (p.name);

CREATE INDEX pathway_name IF NOT EXISTS
FOR (pw:Pathway) ON (pw.name);

// Create composite indexes
CREATE INDEX interaction_confidence IF NOT EXISTS
FOR ()-[i:BINDS_TO]-() ON (i.confidence);

CREATE INDEX pathway_participation IF NOT EXISTS
FOR ()-[p:PARTICIPATES_IN]-() ON (p.role);

// Create full-text search indexes
CALL db.index.fulltext.createNodeIndex(
    "compound_search",
    ["Compound"],
    ["name", "synonyms", "description"]
) IF NOT EXISTS;

CALL db.index.fulltext.createNodeIndex(
    "protein_search", 
    ["Protein"],
    ["name", "gene_symbol", "description"]
) IF NOT EXISTS;

CALL db.index.fulltext.createNodeIndex(
    "pathway_search",
    ["Pathway"],
    ["name", "description", "category"]
) IF NOT EXISTS;
EOF
    
    log_info "Neo4j setup complete"
}

# PostgreSQL Setup
setup_postgres() {
    log_info "Setting up PostgreSQL database..."
    
    # Wait for PostgreSQL to be ready
    until pg_isready -h localhost -p 5432 -U postgres; do
        log_info "Waiting for PostgreSQL to start..."
        sleep 5
    done
    
    # Create MindsDB database and tables
    PGPASSWORD="${POSTGRES_PASSWORD:-postgres123}" psql -h localhost -U postgres <<EOF
-- Create MindsDB database
CREATE DATABASE IF NOT EXISTS mindsdb_db;

-- Connect to MindsDB database
\c mindsdb_db;

-- Create schema for dietary data
CREATE SCHEMA IF NOT EXISTS diet;

-- Create tables for caching and metadata
CREATE TABLE IF NOT EXISTS diet.compounds (
    cid VARCHAR(50) PRIMARY KEY,
    smiles TEXT NOT NULL,
    name VARCHAR(255),
    molecular_weight FLOAT,
    logp FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS diet.predictions (
    id SERIAL PRIMARY KEY,
    compound_id VARCHAR(50),
    prediction_type VARCHAR(50),
    result JSONB,
    confidence FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS diet.user_sessions (
    session_id UUID PRIMARY KEY,
    user_id VARCHAR(100),
    context JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_compounds_smiles ON diet.compounds(smiles);
CREATE INDEX idx_predictions_compound ON diet.predictions(compound_id);
CREATE INDEX idx_sessions_user ON diet.user_sessions(user_id);
EOF
    
    log_info "PostgreSQL setup complete"
}

# Qdrant Setup
setup_qdrant() {
    log_info "Setting up Qdrant vector database..."
    
    # Wait for Qdrant to be ready
    until curl -s http://localhost:6333/health > /dev/null; do
        log_info "Waiting for Qdrant to start..."
        sleep 5
    done
    
    # Create collections via API
    curl -X PUT "http://localhost:6333/collections/compound_embeddings" \
        -H "Content-Type: application/json" \
        -d '{
            "vectors": {
                "size": 768,
                "distance": "Cosine"
            },
            "optimizers_config": {
                "default_segment_number": 5
            }
        }'
    
    curl -X PUT "http://localhost:6333/collections/pathway_embeddings" \
        -H "Content-Type: application/json" \
        -d '{
            "vectors": {
                "size": 768,
                "distance": "Cosine"
            }
        }'
    
    curl -X PUT "http://localhost:6333/collections/conversation_memory" \
        -H "Content-Type: application/json" \
        -d '{
            "vectors": {
                "size": 384,
                "distance": "Cosine"
            }
        }'
    
    log_info "Qdrant setup complete"
}

# Redis Setup
setup_redis() {
    log_info "Setting up Redis cache..."
    
    # Wait for Redis to be ready
    until redis-cli ping > /dev/null 2>&1; do
        log_info "Waiting for Redis to start..."
        sleep 5
    done
    
    # Configure Redis
    redis-cli <<EOF
CONFIG SET maxmemory 2gb
CONFIG SET maxmemory-policy allkeys-lru
CONFIG SET save ""
EOF
    
    log_info "Redis setup complete"
}

# MindsDB Setup
setup_mindsdb() {
    log_info "Setting up MindsDB..."
    
    # Wait for MindsDB to be ready
    until curl -s http://localhost:47334/api/util/ping > /dev/null; do
        log_info "Waiting for MindsDB to start..."
        sleep 10
    done
    
    # Create knowledge base via API
    curl -X POST "http://localhost:47334/api/knowledge_bases" \
        -H "Content-Type: application/json" \
        -d '{
        "name": "diet_knowledge",
        "description": "Dietary and nutritional knowledge base",
            "embedding_model": "sentence-transformers/all-MiniLM-L6-v2",
            "vector_store": "qdrant",
            "config": {
                "chunk_size": 512,
                "chunk_overlap": 50
            }
        }'
    
    log_info "MindsDB setup complete"
}

# Main execution
main() {
    log_info "Starting database setup for environment: $ENVIRONMENT"
    
    # Check Docker services
    if ! docker-compose ps | grep -q "Up"; then
        log_error "Docker services are not running. Please run 'make start' first."
        exit 1
    fi
    
    # Setup databases in parallel where possible
    setup_neo4j &
    NEO4J_PID=$!
    
    setup_postgres &
    POSTGRES_PID=$!
    
    setup_qdrant &
    QDRANT_PID=$!
    
    setup_redis &
    REDIS_PID=$!
    
    # Wait for parallel setups to complete
    wait $NEO4J_PID
    wait $POSTGRES_PID
    wait $QDRANT_PID
    wait $REDIS_PID
    
    # Setup MindsDB (depends on PostgreSQL)
    setup_mindsdb
    
    log_info "All databases initialized successfully!"
    log_info "You can now run 'make load-data' to import dietary and nutritional data"
}

# Run main function
main "$@"
