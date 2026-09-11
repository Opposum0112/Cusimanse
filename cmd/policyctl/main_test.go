package main

import "testing"

func testPolicy() Policy {
	return Policy{
		Version: 1,
		Host: map[string]string{"credentials": "deny", "unrestricted_mounts": "deny"},
		Privileged: map[string]string{"host_filesystem": "deny", "sudo": "approval-required"},
		Virtualization: map[string]string{"disposable_vm": "approval-required"},
		Network: map[string]string{"localhost_services": "allow"},
		Git: map[string]string{"write": "approval-required"},
	}
}

func TestDecisionFor(t *testing.T) {
	p := testPolicy()
	cases := map[string]string{
		"credentials": "deny",
		"mounts": "deny",
		"host-root": "deny",
		"sudo": "approval-required",
		"vm": "approval-required",
		"network": "allow",
		"git-write": "approval-required",
	}
	for action, want := range cases {
		got, err := decisionFor(action, p)
		if err != nil { t.Fatalf("%s: %v", action, err) }
		if got != want { t.Errorf("%s: got %q want %q", action, got, want) }
	}
}

func TestDecisionForUnknownAction(t *testing.T) {
	if _, err := decisionFor("unknown", testPolicy()); err == nil { t.Fatal("expected unknown action error") }
}
