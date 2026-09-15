package compiler

import "testing"

func TestLoadCatalog(t *testing.T) {
	cat, err := LoadCatalog(repoRoot(t))
	if err != nil {
		t.Fatal(err)
	}
	if len(cat.Experiments) < 4 {
		t.Fatalf("experiments = %v", cat.Experiments)
	}
	if len(cat.Roles) < 3 || len(cat.Skills) < 3 {
		t.Fatalf("roles/skills incomplete: %+v", cat)
	}
}
