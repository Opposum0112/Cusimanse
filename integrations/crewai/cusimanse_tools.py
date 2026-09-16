"""CrewAI-facing tools for the CAR research gateway.

The tools submit declarative proposals to CAR. They do not execute shell commands,
subprocesses, or host operations directly.
"""

from __future__ import annotations

import os
from typing import Any

import requests
from crewai.tools import tool


CAR_URL = os.environ.get("CUSIMANSE_CAR_URL", "http://127.0.0.1:8787")


@tool("car_submit_research_proposal")
def car_submit_research_proposal(
    experiment_id: str,
    intent: str,
    capability: str,
    parameters: dict[str, Any] | None = None,
    complete: bool = False,
) -> str:
    """Submit a typed declarative research proposal to CAR for validation and authorization."""
    response = requests.post(
        f"{CAR_URL}/v1/research/{experiment_id}/proposals",
        json={
            "proposal": {
                "intent": intent,
                "capability": capability,
                "parameters": parameters or {},
                "complete": complete,
            }
        },
        timeout=30,
    )
    response.raise_for_status()
    return response.text


@tool("car_get_research_state")
def car_get_research_state(experiment_id: str) -> str:
    """Read CAR-owned research state for an experiment."""
    response = requests.get(
        f"{CAR_URL}/v1/research/{experiment_id}/state", timeout=15
    )
    response.raise_for_status()
    return response.text


@tool("car_get_evidence")
def car_get_evidence(experiment_id: str) -> str:
    """Read preserved CAR evidence references for an experiment."""
    response = requests.get(
        f"{CAR_URL}/v1/research/{experiment_id}/evidence", timeout=15
    )
    response.raise_for_status()
    return response.text


CAR_TOOLS = [
    car_submit_research_proposal,
    car_get_research_state,
    car_get_evidence,
]
