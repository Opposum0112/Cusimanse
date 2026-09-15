package policy

import (
 "encoding/json"
 "fmt"
 "os"
 "path/filepath"
 "strings"
 "time"

 "github.com/opposum0112/Cusimanse/internal/model"
 "gopkg.in/yaml.v3"
)

type Policy struct {
 Version int `yaml:"version"`
 Host struct { Credentials string `yaml:"credentials"`; UnrestrictedMounts string `yaml:"unrestricted_mounts"`; UntrustedHostExecution string `yaml:"untrusted_host_execution"` } `yaml:"host"`
 Privileged struct { Default string `yaml:"default"`; Sudo string `yaml:"sudo"`; HostFilesystem string `yaml:"host_filesystem"`; NetworkReconfiguration string `yaml:"network_reconfiguration"` } `yaml:"privileged"`
 Virtualization struct { DisposableVM string `yaml:"disposable_vm"`; Lima string `yaml:"lima"`; QEMU string `yaml:"qemu"` } `yaml:"virtualization"`
 Network struct { PublicMCP string `yaml:"public_mcp"`; PublicGateway string `yaml:"public_gateway"`; LocalhostServices string `yaml:"localhost_services"` } `yaml:"network"`
 Git struct { Read string `yaml:"read"`; Write string `yaml:"write"`; Push string `yaml:"push"` } `yaml:"git"`
 Orchestration struct { CompetingOrchestrator string `yaml:"competing_orchestrator"`; PrimaryAgentNativeOrchestration string `yaml:"primary_agent_native_orchestration"`; LearningHelpers string `yaml:"learning_helpers"` } `yaml:"orchestration"`
 Evidence struct { PreserveBeforeDestroy string `yaml:"preserve_before_destroy"`; Hashing string `yaml:"hashing"` } `yaml:"evidence"`
}

type FileEngine struct { Root, PolicyFile, AuditFile string }
func NewFileEngine(root string) *FileEngine { p:=os.Getenv("CUSIMANSE_POLICY_FILE");if p==""{p=filepath.Join(root,"policies/host-policy.yaml")};a:=os.Getenv("CUSIMANSE_POLICY_AUDIT");if a==""{a=filepath.Join(root,"runs/policy-decisions.jsonl")};return &FileEngine{root,p,a} }
func (e *FileEngine) Load()(Policy,error){b,err:=os.ReadFile(e.PolicyFile);if err!=nil{return Policy{},err};var p Policy;if err=yaml.Unmarshal(b,&p);err!=nil{return p,fmt.Errorf("parse policy: %w",err)};return p,nil}
func (e *FileEngine) Validate()error{p,err:=e.Load();if err!=nil{return err};if p.Version<1{return fmt.Errorf("policy version is required")};v:=[]string{p.Host.Credentials,p.Host.UnrestrictedMounts,p.Host.UntrustedHostExecution,p.Privileged.Sudo,p.Privileged.HostFilesystem,p.Virtualization.DisposableVM,p.Virtualization.Lima,p.Virtualization.QEMU,p.Network.PublicMCP,p.Network.PublicGateway,p.Network.LocalhostServices,p.Git.Read,p.Git.Write,p.Git.Push,p.Orchestration.CompetingOrchestrator,p.Orchestration.PrimaryAgentNativeOrchestration,p.Orchestration.LearningHelpers,p.Evidence.PreserveBeforeDestroy,p.Evidence.Hashing};for _,x:=range v{if strings.TrimSpace(x)==""{return fmt.Errorf("policy contains an empty required decision")}};return nil}
func (e *FileEngine) Decision(action string)(string,error){p,err:=e.Load();if err!=nil{return "",err};switch strings.ToLower(strings.TrimSpace(action)){case "credentials":return p.Host.Credentials,nil;case "mounts","host-mounts","unrestricted_mounts":return p.Host.UnrestrictedMounts,nil;case "host-root","host-filesystem":return p.Privileged.HostFilesystem,nil;case "sudo":return p.Privileged.Sudo,nil;case "vm","disposable-vm","disposable_vm":return p.Virtualization.DisposableVM,nil;case "lima":return p.Virtualization.Lima,nil;case "qemu":return p.Virtualization.QEMU,nil;case "network","localhost-network","localhost-services","localhost_services":return p.Network.LocalhostServices,nil;case "public-mcp":return p.Network.PublicMCP,nil;case "public-gateway":return p.Network.PublicGateway,nil;case "git-read","read":return p.Git.Read,nil;case "git-write","write":return p.Git.Write,nil;case "push":return p.Git.Push,nil;case "learning","learning-helpers","learning_helpers":return p.Orchestration.LearningHelpers,nil;case "host-execution","untrusted-host-execution":return p.Host.UntrustedHostExecution,nil;case "network-reconfig","network-reconfiguration":return p.Privileged.NetworkReconfiguration,nil;case "competing-orchestrator":return p.Orchestration.CompetingOrchestrator,nil;case "primary-agent-native-orchestration":return p.Orchestration.PrimaryAgentNativeOrchestration,nil;default:return "",fmt.Errorf("unknown policy action: %s",action)}}
func (e *FileEngine) Evaluate(action string,approved bool)model.Decision{if err:=e.Validate();err!=nil{return model.Decision{Action:action,Decision:model.PolicyDeny,Reason:err.Error()}};v,err:=e.Decision(action);if err!=nil{return model.Decision{Action:action,Decision:model.PolicyDeny,Reason:err.Error()}};switch strings.ToLower(v){case "allow","allowed","controlled","required":return model.Decision{Action:action,Decision:model.PolicyAllow,Reason:"policy allows action"};case "approval-required","approval_required","approval":if approved{return model.Decision{Action:action,Decision:model.PolicyAllow,Reason:"explicit approval supplied"}};return model.Decision{Action:action,Decision:model.PolicyApprovalRequired,Reason:"explicit researcher approval is required"};case "deny","denied":return model.Decision{Action:action,Decision:model.PolicyDeny,Reason:"policy denies action"};default:return model.Decision{Action:action,Decision:model.PolicyDeny,Reason:fmt.Sprintf("unsupported policy decision %q",v)}}}
func(e *FileEngine)Audit(d model.Decision)error{if err:=os.MkdirAll(filepath.Dir(e.AuditFile),0755);err!=nil{return err};f,err:=os.OpenFile(e.AuditFile,os.O_CREATE|os.O_APPEND|os.O_WRONLY,0644);if err!=nil{return err};defer f.Close();b,_:=json.Marshal(map[string]string{"action":d.Action,"decision":string(d.Decision),"reason":d.Reason,"timestamp":time.Now().UTC().Format(time.RFC3339)});_,err=f.Write(append(b,'\n'));return err}
