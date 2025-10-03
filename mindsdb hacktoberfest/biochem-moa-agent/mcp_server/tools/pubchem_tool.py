"""
PubChem Integration Tool
========================

Provides access to PubChem's extensive chemical compound database for
retrieving molecular structures of nutrients, bioactivity data, and nutritional properties.

This tool enables:
- Compound search by name, SMILES, InChI, or CID
- Bioactivity data retrieval
- Structural similarity search
- Property calculation (MW, LogP, TPSA, etc.)
- Biological target identification
- Cross-reference to other databases

Main Functions:
--------------
search_compound(query: str) -> CompoundData:
    Search for compounds by name or identifier
    
get_bioactivity(cid: int) -> List[BioActivity]:
    Retrieve bioactivity assay results for a compound
    
find_similar(smiles: str, threshold: float) -> List[CompoundData]:
    Find structurally similar compounds using Tanimoto similarity
    
get_targets(cid: int) -> List[ProteinTarget]:
    Get known protein targets for a compound
    
calculate_properties(smiles: str) -> MolecularProperties:
    Calculate molecular descriptors and ADMET properties

Data Classes:
------------
CompoundData: Complete compound information including structure
BioActivity: Bioassay results with IC50/EC50 values
ProteinTarget: Protein target information with binding affinity
MolecularProperties: Calculated molecular descriptors

API Endpoints Used:
------------------
- PUG REST: RESTful interface for compound data
- PUG View: Table and structure data
- Power User Gateway: Advanced queries
- Classification Browser: Compound classification

Rate Limiting:
-------------
- 5 requests per second for PUG REST
- 400 requests per minute total
- Automatic retry with exponential backoff

Caching:
--------
- Redis cache for frequently accessed compounds
- 24-hour TTL for compound data
- 7-day TTL for bioactivity data

Error Handling:
--------------
- Graceful fallback for missing data
- Validation of chemical structures
- Network error recovery

Example Usage:
-------------
    tool = PubChemTool(api_key="your_key")
    
    # Search for aspirin
    compound = tool.search_compound("aspirin")
    
    # Get bioactivity data
    activities = tool.get_bioactivity(compound.cid)
    
    # Find similar compounds
    similar = tool.find_similar(compound.smiles, threshold=0.8)
"""
