package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"
)

func main() {
	fmt.Println("Cusimanse host setup")
	fmt.Printf("Host: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	fmt.Println("The installer invokes the existing host prerequisite script so package-manager behavior remains centralized.")
	fmt.Println()
	fmt.Println("1) Install mandatory host components")
	fmt.Println("2) Install all optional research, observability and tracing components")
	fmt.Println("3) Install mandatory agent observability stack")
	fmt.Println("4) Exit")
	fmt.Print("Select [1-4]: ")

	choice, _ := bufio.NewReader(os.Stdin).ReadString('\n')
	choice = strings.TrimSpace(choice)
	switch choice {
	case "1":
		run("./scripts/prerequisites.sh")
	case "2":
		runEnv("./scripts/prerequisites.sh", "CUSIMANSE_INSTALL_PRODUCTION_PROFILE=1")
	case "3":
		runEnv("./scripts/prerequisites.sh", "CUSIMANSE_INSTALL_OBSERVABILITY=1")
	case "4":
		return
	default:
		fmt.Fprintln(os.Stderr, "invalid selection")
		os.Exit(2)
	}
}

func run(path string) {
	cmd := exec.Command("bash", path)
	cmd.Stdout, cmd.Stderr, cmd.Stdin = os.Stdout, os.Stderr, os.Stdin
	if err := cmd.Run(); err != nil { os.Exit(1) }
}

func runEnv(path, setting string) {
	parts := strings.SplitN(setting, "=", 2)
	if len(parts) != 2 { os.Exit(2) }
	env := append(os.Environ(), setting)
	cmd := exec.Command("bash", path)
	cmd.Env, cmd.Stdout, cmd.Stderr, cmd.Stdin = env, os.Stdout, os.Stderr, os.Stdin
	if err := cmd.Run(); err != nil { os.Exit(1) }
	_ = parts
}
