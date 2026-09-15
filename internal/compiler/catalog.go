package compiler

import (
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

type Catalog struct {
	Experiments []string `json:"experiments"`
	HostPrep    []string `json:"hostPrep"`
	Roles       []string `json:"roles"`
	Skills      []string `json:"skills"`
}

type skillRegistry struct {
	Skills []struct {
		ID   string `yaml:"id"`
		Path string `yaml:"path"`
	} `yaml:"skills"`
	Roles []struct {
		ID   string `yaml:"id"`
		Path string `yaml:"path"`
	} `yaml:"roles"`
}

type bindingsDoc struct {
	Bindings map[string][]string `yaml:"bindings"`
}

func LoadCatalog(root string) (Catalog, error) {
	var cat Catalog
	exps, err := filepath.Glob(filepath.Join(root, "experiments", "*.yaml"))
	if err != nil {
		return cat, err
	}
	for _, p := range exps {
		doc, err := Load(p)
		if err != nil {
			return cat, fmt.Errorf("%s: %w", p, err)
		}
		cat.Experiments = append(cat.Experiments, doc.Metadata.ID)
		if _, err := LoadHostPrep(root, doc.Spec.HostPrep); err != nil {
			return cat, fmt.Errorf("host-prep for %s: %w", doc.Metadata.ID, err)
		}
	}

	regb, err := os.ReadFile(filepath.Join(root, "roles", "skill-registry.yaml"))
	if err != nil {
		return cat, err
	}
	var reg skillRegistry
	if err := yaml.Unmarshal(regb, &reg); err != nil {
		return cat, err
	}
	for _, r := range reg.Roles {
		if _, err := os.Stat(filepath.Join(root, r.Path)); err != nil {
			return cat, fmt.Errorf("role missing: %s", r.Path)
		}
		cat.Roles = append(cat.Roles, r.ID)
	}
	for _, s := range reg.Skills {
		if _, err := os.Stat(filepath.Join(root, s.Path)); err != nil {
			return cat, fmt.Errorf("skill missing: %s", s.Path)
		}
		cat.Skills = append(cat.Skills, s.ID)
	}

	bb, err := os.ReadFile(filepath.Join(root, "roles", "bindings.yaml"))
	if err != nil {
		return cat, err
	}
	var bind bindingsDoc
	if err := yaml.Unmarshal(bb, &bind); err != nil {
		return cat, err
	}
	skillSet := map[string]struct{}{}
	for _, id := range cat.Skills {
		skillSet[id] = struct{}{}
	}
	for role, skills := range bind.Bindings {
		found := false
		for _, id := range cat.Roles {
			if id == role {
				found = true
			}
		}
		if !found {
			return cat, fmt.Errorf("binding for unknown role %s", role)
		}
		for _, sk := range skills {
			if _, ok := skillSet[sk]; !ok {
				return cat, fmt.Errorf("binding %s uses unknown skill %s", role, sk)
			}
		}
	}

	hosts, err := filepath.Glob(filepath.Join(root, "host-prep", "*.yaml"))
	if err != nil {
		return cat, err
	}
	for _, p := range hosts {
		cat.HostPrep = append(cat.HostPrep, filepath.Base(p))
	}
	return cat, nil
}
