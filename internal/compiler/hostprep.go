package compiler

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

type HostPrepDoc struct {
	Kind        string                    `yaml:"kind"`
	ID          string                    `yaml:"id"`
	Fallback    string                    `yaml:"fallback"`
	Categories  map[string][]HostPrepStep `yaml:"categories"`
}

type HostPrepStep struct {
	ID            string   `yaml:"id"`
	Check         string   `yaml:"check"`
	Optional      bool     `yaml:"optional"`
	Required      bool     `yaml:"required"`
	Distributions []string `yaml:"distributions"`
	Fallback      string   `yaml:"fallback"`
}

type HostPrepStatus struct {
	ID     string `json:"id"`
	Status string `json:"status"`
	Detail string `json:"detail,omitempty"`
}

func LoadHostPrep(root, id string) (HostPrepDoc, error) {
	var doc HostPrepDoc
	if id == "none" {
		return doc, nil
	}
	path := filepath.Join(root, "host-prep", id+".yaml")
	b, err := os.ReadFile(path)
	if err != nil {
		return doc, err
	}
	if err := yaml.Unmarshal(b, &doc); err != nil {
		return doc, err
	}
	if doc.Kind != "HostPrep" {
		return doc, fmt.Errorf("host-prep kind must be HostPrep")
	}
	return doc, nil
}

func (d HostPrepDoc) Check(root string) []HostPrepStatus {
	out := []HostPrepStatus{}
	if d.ID == "" {
		return out
	}
	for cat, steps := range d.Categories {
		for _, step := range steps {
			st := HostPrepStatus{ID: cat + "/" + step.ID}
			if step.Check == "" || step.Check == "true" {
				st.Status = "DECLARED"
				out = append(out, st)
				continue
			}
			parts := strings.Fields(step.Check)
			bin := parts[0]
			if _, err := exec.LookPath(bin); err != nil {
				st.Status = "NOT_DEPLOYED"
				st.Detail = bin + " missing"
				if step.Required {
					st.Status = "REQUIRED_MISSING"
				}
				out = append(out, st)
				continue
			}
			st.Status = "OK"
			out = append(out, st)
		}
	}
	_ = root
	return out
}
