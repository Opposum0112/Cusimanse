package preflight

import (
 "fmt"
 "os"
 "os/exec"
 "path/filepath"
 "runtime"
)

type Result struct { Platform string; Missing []string }
type Checker struct { Root string; LookPath func(string)(string,error) }
func New(root string) Checker{return Checker{Root:root,LookPath:exec.LookPath}}
func (c Checker) Check() Result {r:=Result{Platform:runtime.GOOS};if r.Platform=="windows"{r.Missing=append(r.Missing,"wsl2-for-full-experiments");return r};for _,x:=range []string{"go","git"}{if _,err:=c.LookPath(x);err!=nil{r.Missing=append(r.Missing,"host-command:"+x)}};for _,x:=range []string{"recipes/lima/security-research.yaml","recipes/instrumentation/security-research.yaml","recipes/session/session-state.yaml"}{if _,err:=os.Stat(filepath.Join(c.Root,x));err!=nil{r.Missing=append(r.Missing,x)}};return r}
func (c Checker) Validate()error{r:=c.Check();if len(r.Missing)>0{return fmt.Errorf("preflight failed: %v",r.Missing)};return nil}
