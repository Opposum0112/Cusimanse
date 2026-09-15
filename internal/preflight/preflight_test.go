package preflight

import("os";"path/filepath";"testing")
func TestCheckReportsMissingDependencies(t *testing.T){d:=t.TempDir();_ = os.MkdirAll(filepath.Join(d,"recipes/lima"),0755);_ = os.WriteFile(filepath.Join(d,"recipes/lima/security-research.yaml"),[]byte("ok"),0600);_ = os.WriteFile(filepath.Join(d,"recipes/instrumentation-security-research.yaml"),[]byte("ok"),0600);c:=New(d);c.LookPath=func(s string)(string,error){return "",os.ErrNotExist};r:=c.Check();if len(r.Missing)==0{t.Fatal("expected missing dependencies")}}
