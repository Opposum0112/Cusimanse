package policy

import("os";"path/filepath";"testing")
func TestFileEngineEvaluate(t *testing.T){d:=t.TempDir();p:=filepath.Join(d,"policy.yaml");s:=`version: 1
host:
  credentials: deny
  unrestricted_mounts: deny
  untrusted_host_execution: deny
privileged:
  default: approval-required
  sudo: approval-required
  host_filesystem: deny
  network_reconfiguration: approval-required
virtualization:
  disposable_vm: approval-required
  lima: allow
  qemu: allow
network:
  public_mcp: deny
  public_gateway: deny
  localhost_services: allow
git:
  read: allow
  write: approval-required
  push: approval-required
orchestration:
  competing_orchestrator: deny
  primary_agent_native_orchestration: allow
  learning_helpers: approval-required
evidence:
  preserve_before_destroy: required
  hashing: required
`;if err:=os.WriteFile(p,[]byte(s),0600);err!=nil{t.Fatal(err)};e:=&FileEngine{PolicyFile:p,AuditFile:filepath.Join(d,"audit.jsonl")};if err:=e.Validate();err!=nil{t.Fatal(err)};if d:=e.Evaluate("credentials",false);d.Decision!="deny"{t.Fatalf("credentials=%s",d.Decision)};if d:=e.Evaluate("vm",false);d.Decision!="approval-required"{t.Fatalf("vm=%s",d.Decision)};if d:=e.Evaluate("vm",true);d.Decision!="allow"{t.Fatalf("approved vm=%s",d.Decision)};if d:=e.Evaluate("unknown",false);d.Decision!="deny"{t.Fatalf("unknown=%s",d.Decision)}}
