package validation

import (
 "encoding/json"
 "fmt"
 "os"
 "path/filepath"
 "strings"

 "github.com/opposum0112/Cusimanse/internal/policy"
 "gopkg.in/yaml.v3"
)

type Validator struct { Root string }
func New(root string) Validator{return Validator{Root:root}}
func (v Validator) RequireFiles(patterns ...string) error {for _,p:=range patterns{matches,err:=filepath.Glob(filepath.Join(v.Root,p));if err!=nil{return err};if len(matches)==0{return fmt.Errorf("required path pattern has no matches: %s",p)};for _,m:=range matches{st,err:=os.Stat(m);if err!=nil{return err};if st.IsDir()||st.Size()==0{return fmt.Errorf("missing/empty: %s",m)}}};return nil}
func (v Validator) JSON(path string)error{b,err:=os.ReadFile(filepath.Join(v.Root,path));if err!=nil{return err};var x any;if err=json.Unmarshal(b,&x);err!=nil{return fmt.Errorf("parse %s: %w",path,err)};return nil}
func (v Validator) YAML(path string)error{b,err:=os.ReadFile(filepath.Join(v.Root,path));if err!=nil{return err};var x any;if err=yaml.Unmarshal(b,&x);err!=nil{return fmt.Errorf("parse %s: %w",path,err)};return nil}
func (v Validator) Contracts() error {
 matches,err:=filepath.Glob(filepath.Join(v.Root,"contracts","*.md"));if err!=nil{return err}
 for _,path:=range matches{
  base:=filepath.Base(path);id:=strings.TrimSuffix(base,".md")
  if id=="README"||id=="acceptance"||id=="agent-adapter"{continue}
  b,err:=os.ReadFile(path);if err!=nil{return err};text:=string(b)
  if !strings.Contains(text,"## Scope"){return fmt.Errorf("contract %s missing Scope section",path)}
  if !strings.Contains(text,"## Acceptance"){return fmt.Errorf("contract %s missing Acceptance section",path)}
  if !strings.Contains(text,"## Purpose")&&!strings.Contains(text,"## Why"){return fmt.Errorf("contract %s missing Purpose/Why section",path)}
  artifacts:=[]string{filepath.Join(v.Root,"recipes","experiments",id+".yaml"),filepath.Join(v.Root,"recipes",id,"recipe.yaml"),filepath.Join(v.Root,"prompts","experiments",id+".md")}
  for _,artifact:=range artifacts{st,err:=os.Stat(artifact);if err!=nil||st.IsDir()||st.Size()==0{return fmt.Errorf("contract %s missing matching artifact: %s",path,artifact)}}
  experiment,err:=os.ReadFile(artifacts[0]);if err!=nil{return err}
  if !strings.Contains(string(experiment),"contract: contracts/"+base){return fmt.Errorf("experiment configuration does not reference %s",base)}
 }
 return nil
}
func (v Validator) Project() error {required:=[]string{"contracts/*.md","recipes/*/recipe.yaml","recipes/experiments/*.yaml","recipes/profiles/registry.yaml","recipes/profiles/host/*.yaml","recipes/profiles/workload/*.yaml","recipes/subrecipes/*.yaml","recipes/lima/security-research.yaml","recipes/instrumentation/security-research.yaml","recipes/host/security-research.yaml","recipes/gateway/mandatory.yaml","recipes/observability/mandatory.yaml","recipes/session/session-state.yaml","recipes/session/learning-workflow.yaml","recipes/agents/*.yaml","recipes/skills/*.yaml","recipes/skills/registry.yaml","recipes/agents/role-skill-registry.json","recipes/agents/role-skill-bindings.yaml","recipes/mcp/registry.yaml","policies/*.yaml","manifest/PACKAGE-MANIFEST.json","manifest/TOOL-INVENTORY.yaml","docs/RESEARCHER-GUIDE.md","docs/architecture/cusimanse-architecture.mmd","docs/architecture/cusimanse-architecture.svg"};if err:=v.RequireFiles(required...);err!=nil{return err};if err:=v.JSON("manifest/PACKAGE-MANIFEST.json");err!=nil{return err};if err:=v.JSON("recipes/agents/role-skill-registry.json");err!=nil{return err};for _,p:=range []string{"policies/host-policy.yaml","recipes/profiles/registry.yaml","recipes/session/learning-workflow.yaml","recipes/observability/mandatory.yaml","recipes/agents/role-skill-bindings.yaml","manifest/TOOL-INVENTORY.yaml"}{if err:=v.YAML(p);err!=nil{return err}};if err:=v.Contracts();err!=nil{return err};if err:=policy.NewFileEngine(v.Root).Validate();err!=nil{return fmt.Errorf("policy validation: %w",err)};return nil}
func (v Validator) NoMarker(marker string,paths ...string)error{for _,root:=range paths{matches,err:=filepath.Glob(filepath.Join(v.Root,root));if err!=nil{return err};for _,m:=range matches{st,err:=os.Stat(m);if err!=nil{return err};if st.IsDir(){continue};b,err:=os.ReadFile(m);if err!=nil{return err};if strings.Contains(string(b),marker){return fmt.Errorf("forbidden marker %q found in %s",marker,m)}}};return nil}
func (v Validator) NoRefactorReferences(paths ...string) error {return v.NoMarker("refactor",paths...)}
