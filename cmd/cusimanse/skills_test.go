package main

import "testing"

func TestRoleSkillRegistryValidation(t *testing.T) {
	r := RoleSkillRegistry{Version:1, Skills:[]Skill{{Name:"run"}}, Roles:[]Role{{Name:"researcher", Skills:[]string{"run"}}}}
	if err := validateRoleSkillRegistry(r); err != nil { t.Fatal(err) }
}

func TestRoleSkillRegistryRejectsUnknownSkill(t *testing.T) {
	r := RoleSkillRegistry{Version:1, Skills:[]Skill{}, Roles:[]Role{{Name:"researcher", Skills:[]string{"missing"}}}}
	if err := validateRoleSkillRegistry(r); err == nil { t.Fatal("expected unknown skill to fail") }
}
