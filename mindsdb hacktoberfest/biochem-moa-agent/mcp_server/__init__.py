"""
DietMOA MCP Server
==================

A Model Context Protocol (MCP) server providing dietary and nutritional analysis tools
for food-nutrient interaction prediction and metabolic pathway impact assessment.

This server implements the MCP specification to expose various dietary analysis
tools that can be consumed by AI agents for nutritional mechanism of action
(MoA) prediction and metabolic pathway analysis.

Main Components:
---------------
- PubChem Tool: Chemical compound data retrieval and analysis
- Cypher Tool: Graph database queries for pathway traversal
- Memory Tool: Contextual memory management for conversation history
- Pathway Tool: Metabolic pathway analysis and visualization

Author: DietMOA Team
Version: 1.0.0
License: MIT
"""

from .server import MCPServer
from .handlers import DietHandler

__version__ = "1.0.0"
__all__ = ["MCPServer", "DietHandler"]
