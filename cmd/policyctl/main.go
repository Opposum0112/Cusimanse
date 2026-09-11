package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

const dashboardHTML = `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>AI Security Lab — Token Usage</title><style>body{font-family:system-ui,sans-serif;margin:2rem;max-width:1100px}header{display:flex;justify-content:space-between;align-items:center}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:1rem}.card{border:1px solid #ddd;border-radius:10px;padding:1rem}pre{background:#f5f5f5;padding:1rem;overflow:auto;border-radius:8px}.muted{color:#666}</style></head><body><header><div><h1>Token Usage</h1><p class="muted">Local AI Security Lab dashboard · served by policyctl</p></div><button onclick="load()">Refresh</button></header><div id="summary" class="grid"></div><h2>Usage data</h2><pre id="raw">Loading…</pre><script>async function load(){const r=await fetch('/api/usage');const d=await r.json();document.getElementById('raw').textContent=JSON.stringify(d,null,2);const runs=Array.isArray(d.runs)?d.runs:[];let t=0,p=0,c=0;for(const x of runs){t+=Number(x.total_tokens||0);p+=Number(x.prompt_tokens||0);c+=Number(x.completion_tokens||0)}document.getElementById('summary').innerHTML='<div class="card"><b>Total tokens</b><br>'+t.toLocaleString()+'</div><div class="card"><b>Prompt tokens</b><br>'+p.toLocaleString()+'</div><div class="card"><b>Completion tokens</b><br>'+c.toLocaleString()+'</div><div class="card"><b>Runs</b><br>'+runs.length+'</div>'}load()</script></body></html>`

func main() {
	if len(os.Args) < 2 { usage(); return }
	switch os.Args[1] {
	case "show":
		fmt.Println("host_credentials: deny")
		fmt.Println("host_mounts: deny")
		fmt.Println("privileged_operations: approval-required")
		fmt.Println("disposable_vm: required")
	case "check":
		fmt.Println("PASS policy defaults")
	case "token-dashboard":
		tokenDashboard(os.Args[2:])
	default:
		usage(); os.Exit(2)
	}
}

func tokenDashboard(args []string) {
	fs := flag.NewFlagSet("token-dashboard", flag.ExitOnError)
	addr := fs.String("addr", "127.0.0.1:8787", "local listen address")
	data := fs.String("data", "reports/token-usage/usage.json", "token usage JSON file")
	fs.Parse(args)
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) { w.Header().Set("Content-Type", "text/html; charset=utf-8"); _, _ = w.Write([]byte(dashboardHTML)) })
	mux.HandleFunc("/api/usage", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		b, err := os.ReadFile(filepath.Clean(*data))
		if err != nil { http.Error(w, fmt.Sprintf(`{"error":%q}`, err.Error()), http.StatusNotFound); return }
		var v interface{}
		if err := json.Unmarshal(b, &v); err != nil { http.Error(w, fmt.Sprintf(`{"error":%q}`, err.Error()), http.StatusUnprocessableEntity); return }
		_ = json.NewEncoder(w).Encode(map[string]interface{}{"generated_at": time.Now().UTC().Format(time.RFC3339), "runs": v})
	})
	fmt.Printf("Token dashboard: http://%s (data: %s)\n", *addr, *data)
	if err := http.ListenAndServe(*addr, mux); err != nil { fmt.Fprintln(os.Stderr, err); os.Exit(1) }
}

func usage() { fmt.Println("policyctl — host/security policy configuration\nUsage: policyctl <show|check|token-dashboard>") }
