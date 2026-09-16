"""CrewAI-facing tools for the Cusimanse Agent Runtime.

This module intentionally contains no host execution primitives. It sends
structured research proposals to a CAR-compatible HTTP endpoint. CAR remains
the authority for validation, policy, approval and execution.
"""

from __future__ import annotations

import json
import os
from typing import Any
from urllib.request import Request, urlopen

try:
    from crewai.tools import tool
except ImportError:  # pragma: no cover - permits documentation/import inspection without CrewAI
    def tool(fn):
        return fn


CAR_URL = os.environ.get("CUSIMANSE_CAR_URL", "http://127.0.0.1:8787")


def _post(path: str, payload: dict[str, Any]) -> dict[str, Any]:
    request = Request(
        f"{CAR_URL.rstrip('/')}{path}",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


@tool("cusimanse_submit_research_intent")
def submit_research_intent(
    skill: str,
    intent: str,
    parameters_json: str = "{}",
    complete: bool = False,
) -> str:
    """Submit a declarative research intent to CAR for validation and authorization."""
    parameters = json.loads(parameters_json)
    result = _post(
        "/v1/research/intents",
        {
            "skill": skill,
            "intent": intent,
            "parameters": parameters,
            "complete": complete,
        },
    )
    return json.dumps(result, sort_keys=True)


@tool("cusimanse_get_research_state")
def get_research_state(experiment_id: str) -> str:
    """Read CAR-owned research state for a CrewAI research cycle."""
    request = Request(
        f"{CAR_URL.rstrip('/')}/v1/research/{experiment_id}/state",
        headers={"Accept": "application/json"},
        method="GET",
    )
    with urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8")


@tool("cusimanse_get_evidence")
def get_evidence(experiment_id: str) -> str:
    """Read CAR-preserved evidence references for a research experiment."""
    request = Request(
        f"{CAR_URL.rstrip('/')}/v1/research/{experiment_id}/evidence",
        headers={"Accept": "application/json"},
        method="GET",
    )
    with urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8")
