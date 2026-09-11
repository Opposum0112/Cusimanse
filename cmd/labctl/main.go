// labctl is the future single-binary control plane for the AI Security Lab.
//
// This initial command intentionally reports the architecture boundary rather
// than pretending to replace the existing Python implementation. The Go
// binary will become the stable cross-platform entry point as subcommands are
// migrated behind the same deployment contract.
package main

import "fmt"

const version = "0.2.0-dev"

func main() {
	fmt.Printf("labctl %s\n", version)
	fmt.Println("Go control-plane bootstrap; deployment commands are being migrated from the legacy Python controller.")
}
