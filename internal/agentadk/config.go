package agentadk

import "os"

// Config controls the native ADK Go 2 security research agent.
type Config struct {
	AppName string
	Model   string
	Approved bool
}

func DefaultConfig() Config {
	model := os.Getenv("CUSIMANSE_MODEL")
	if model == "" {
		model = "gemini-2.5-flash"
	}
	return Config{
		AppName: "cusimanse-security-research",
		Model: model,
	}
}
