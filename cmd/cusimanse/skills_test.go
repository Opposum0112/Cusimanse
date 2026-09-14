package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestRoleSkillRegistryValidation(t *testing.T) {
	r := RoleSkillRegistry{Version:1, Skills:[]Skill{{Name:"run"}}, Roles:[]Role{{Name:"researcher", Skills:[]string{"run"}}}}
	if err := validateRoleSkillRegistry(r); err != nil { t.Fatal(err) }
}

func TestRoleSkillRegistryRejectsUnknownSkill(t *testing.T) {
	r := RoleSkillRegistry{Version:1, Skills:[]Skill{}, Roles:[]Role{{Name:"researcher", Skills:[]string{"missing"}}}}
	if err := validateRoleSkillRegistry(r); err == nil { t.Fatal("expected unknown skill to fail") }
}

func TestRoleSkillRegistryRejectsDuplicateNames(t *testing.T) {
	r := RoleSkillRegistry{Version:1, Skills:[]Skill{{Name:"run"},{Name:"run"}}}
	if err := validateRoleSkillRegistry(r); err == nil { t.Fatal("expected duplicate skill to fail") }
}

func TestRoleSkillRegeneration(t *testing.T) {
	root := t.TempDir()
	if err := os.MkdirAll(filepath.Join(root,"recipes","agents"),0755); err != nil { t.Fatal(err) }
	r := RoleSkillRegistry{Version:1, Skills:[]Skill{{Name:"report",Version:1,Description:"make report",Capabilities:[]string{"collect"},RequiredTools:[]string{"jq"}}}, Roles:[]Role{{Name:"reporter",Version:1,Description:"report findings",Skills:[]string{"report"},Capabilities:[]string{"collect"}}}}
	if err := writeRoleSkillRegistry(root,r); err != nil { t.Fatal(err) }
	if err := syncRoleSkillConsumers(root,r); err != nil { t.Fatal(err) }
	for _,p := range []string{"recipes/skills/report.yaml",".agents/agents/reporter.yaml","recipes/agents/role-skill-bindings.yaml"} { if _,err:=os.Stat(filepath.Join(root,p));err!=nil{t.Fatalf("missing generated file %s: %v",p,err)} }
	first,err:=os.ReadFile(filepath.Join(root,"recipes","agents","role-skill-bindings.yaml"));if err!=nil{t.Fatal(err)}
	if err:=syncRoleSkillConsumers(root,r);err!=nil{t.Fatal(err)}
	second,err:=os.ReadFile(filepath.Join(root,"recipes","agents","role-skill-bindings.yaml"));if err!=nil{t.Fatal(err)}
	if string(first)!=string(second){t.Fatal("expected deterministic generated binding")}
}
