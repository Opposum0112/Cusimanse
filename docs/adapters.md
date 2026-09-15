# Adapter contracts

Adapters are the only execution boundary for external tools, APIs, shells, files, networks, and compute. CAR resolves an adapter by an explicitly registered capability; adapters do not receive raw recipes.

One capability maps to one registered adapter. Capability collisions and unknown adapter capabilities are rejected.
