package validation

import (
 "os"
 "path/filepath"
 "testing"
)
func TestNoMarker(t *testing.T){d:=t.TempDir();p:=filepath.Join(d,"x.md");if err:=os.WriteFile(p,[]byte("safe"),0600);err!=nil{t.Fatal(err)};if err:=(Validator{Root:d}).NoMarker("filecite","*.md");err!=nil{t.Fatal(err)};if err:=os.WriteFile(p,[]byte("filecite"),0600);err!=nil{t.Fatal(err)};if err:=(Validator{Root:d}).NoMarker("filecite","*.md");err==nil{t.Fatal("expected marker failure")}}
