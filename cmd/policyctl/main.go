package main

import (
 "encoding/json"
 "errors"
 "flag"
 "fmt"
 "net/http"
 "os"
 "path/filepath"
 "strings"
 "time"

 "gopkg.in/yaml.v3"
)

type Policy struct { Version int `yaml:"version"`; Host map[string]string `yaml:"host"`; Privileged map[string]string `yaml:"privileged"`; Virtualization map[string]string `yaml:"virtualization"`; Network map[string]string `yaml:"network"`; Git map[string]string `yaml:"git"`; Evidence map[string]string `yaml:"evidence"` }
type Decision struct { Action string `json:"action"`; Decision string `json:"decision"`; PolicyFile string `json:"policy_file"`; Timestamp string `json:"timestamp"` }
const defaultPolicy="policies/host-policy.yaml"
const defaultAudit="evidence/audit/policy-decisions.jsonl"
func loadPolicy(path string)(Policy,error){b,e:=os.ReadFile(path);if e!=nil{return Policy{},e};var p Policy;if e=yaml.Unmarshal(b,&p);e!=nil{return Policy{},e};if p.Version==0{return Policy{},errors.New("policy version is required")};return p,nil}
func decisionFor(action string,p Policy)(string,error){m:=map[string]string{"credentials":"host.credentials","mounts":"host.unrestricted_mounts","host-mounts":"host.unrestricted_mounts","host-root":"privileged.host_filesystem","sudo":"privileged.sudo","vm":"virtualization.disposable_vm","network":"network.localhost_services","git-write":"git.write","push":"git.write"};key,ok:=m[strings.ToLower(strings.TrimSpace(action))];if !ok{return "",fmt.Errorf("unknown action %q",action)};parts:=strings.Split(key,".");var v string;switch parts[0]{case "host":v=p.Host[parts[1]];case "privileged":v=p.Privileged[parts[1]];case "virtualization":v=p.Virtualization[parts[1]];case "network":v=p.Network[parts[1]];case "git":v=p.Git[parts[1]]};if v==""{return "",fmt.Errorf("no policy value for %q",action)};return v,nil}
func main(){if len(os.Args)<2{usage();return};switch os.Args[1]{case "show":show(os.Args[2:]);case "validate":validate(os.Args[2:]);case "check":check(os.Args[2:]);case "token-dashboard":tokenDashboard(os.Args[2:]);default:usage();os.Exit(2)}}
func show(args []string){fs:=flag.NewFlagSet("show",flag.ExitOnError);f:=fs.String("file",defaultPolicy,"policy YAML file");fs.Parse(args);p,e:=loadPolicy(*f);if e!=nil{fmt.Fprintln(os.Stderr,e);os.Exit(1)};b,_:=yaml.Marshal(p);fmt.Print(string(b))}
func validate(args []string){fs:=flag.NewFlagSet("validate",flag.ExitOnError);f:=fs.String("file",defaultPolicy,"policy YAML file");fs.Parse(args);if _,e:=loadPolicy(*f);e!=nil{fmt.Fprintln(os.Stderr,e);os.Exit(1)};fmt.Println("PASS policy",*f)}
func check(args []string){fs:=flag.NewFlagSet("check",flag.ExitOnError);f:=fs.String("file",defaultPolicy,"policy YAML file");a:=fs.String("action","","host/security action");audit:=fs.String("audit-file",defaultAudit,"append-only policy decision JSONL");jsonOut:=fs.Bool("json",true,"emit JSON");fs.Parse(args);p,e:=loadPolicy(*f);if e!=nil{fmt.Fprintln(os.Stderr,e);os.Exit(1)};if *a==""{fmt.Println("PASS policy",*f);return};v,e:=decisionFor(*a,p);if e!=nil{fmt.Fprintln(os.Stderr,e);os.Exit(2)};d:=Decision{Action:*a,Decision:v,PolicyFile:*f,Timestamp:time.Now().UTC().Format(time.RFC3339)};if e=appendAudit(*audit,d);e!=nil{fmt.Fprintf(os.Stderr,"warning: audit unavailable: %v\n",e)};if *jsonOut{_ = json.NewEncoder(os.Stdout).Encode(d)}else{fmt.Printf("%s: %s\n",d.Action,d.Decision)}}
func appendAudit(path string,d Decision)error{if path==""{return nil};if e:=os.MkdirAll(filepath.Dir(path),0755);e!=nil{return e};f,e:=os.OpenFile(filepath.Clean(path),os.O_CREATE|os.O_WRONLY|os.O_APPEND,0600);if e!=nil{return e};defer f.Close();b,_:=json.Marshal(d);_,e=f.Write(append(b,'\n'));return e}
const dashboardHTML=`<!doctype html><html><body><h1>AI Security Lab — Token Usage</h1><button onclick="load()">Refresh</button><pre id="raw">Loading…</pre><script>async function load(){const r=await fetch('/api/usage');document.getElementById('raw').textContent=JSON.stringify(await r.json(),null,2)}load()</script></body></html>`
func tokenDashboard(args []string){fs:=flag.NewFlagSet("token-dashboard",flag.ExitOnError);addr:=fs.String("addr","127.0.0.1:8787","local listen address");data:=fs.String("data","reports/token-usage/usage.json","token usage JSON file");fs.Parse(args);mux:=http.NewServeMux();mux.HandleFunc("/",func(w http.ResponseWriter,r *http.Request){w.Header().Set("Content-Type","text/html; charset=utf-8");_,_=w.Write([]byte(dashboardHTML))});mux.HandleFunc("/api/usage",func(w http.ResponseWriter,r *http.Request){w.Header().Set("Content-Type","application/json");b,e:=os.ReadFile(filepath.Clean(*data));if e!=nil{http.Error(w,e.Error(),404);return};var v interface{};if e=json.Unmarshal(b,&v);e!=nil{http.Error(w,e.Error(),422);return};_=json.NewEncoder(w).Encode(map[string]interface{}{"generated_at":time.Now().UTC().Format(time.RFC3339),"runs":v})});fmt.Printf("Token dashboard: http://%s (data: %s)\n",*addr,*data);if e:=http.ListenAndServe(*addr,mux);e!=nil{fmt.Fprintln(os.Stderr,e);os.Exit(1)}}
func usage(){fmt.Println("policyctl — host/security policy interface\nUsage: policyctl <show|validate|check|token-dashboard>\n  check --action <credentials|mounts|host-root|vm|network|git-write|sudo>")}
