package execution

import (
	"fmt"

	"github.com/opposum0112/Cusimanse/internal/model"
)

var transitions = map[model.SessionState][]model.SessionState{
	model.StateCreated:           {model.StateValidated, model.StateFailed},
	model.StateValidated:         {model.StatePlanned, model.StateFailed},
	model.StatePlanned:           {model.StateProvisioned, model.StateFailed},
	model.StateProvisioned:       {model.StateInstrumented, model.StateFailed},
	model.StateInstrumented:      {model.StateExecuting, model.StateFailed},
	model.StateExecuting:         {model.StateEvidenceCollected, model.StateFailed},
	model.StateEvidenceCollected: {model.StateVerified, model.StateFailed},
	model.StateVerified:          {model.StateReported, model.StateFailed},
	model.StateReported:          {model.StatePreserved, model.StateFailed},
	model.StatePreserved:         {model.StateDestroyed, model.StateFailed},
	model.StateFailed:            {model.StateDestroyed},
}

func CanTransition(from, to model.SessionState) bool {
	for _, candidate := range transitions[from] {
		if candidate == to { return true }
	}
	return false
}

func Transition(from, to model.SessionState) error {
	if !CanTransition(from, to) {
		return fmt.Errorf("invalid lifecycle transition %s -> %s", from, to)
	}
	return nil
}
