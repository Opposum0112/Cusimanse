package compiler

import (
	"fmt"
	"os"
	"os/exec"
)

func Execute(root string, doc ExperimentDoc, approved bool) error {
	if err := doc.Validate(); err != nil {
		return err
	}
	if !approved {
		return fmt.Errorf("execute requires --approved")
	}
	bin, err := exec.LookPath("cusimanse")
	if err != nil {
		fmt.Fprintf(os.Stderr, "compile execute: cusimanse not on PATH; printing plan only\n")
		fmt.Printf("plan experiment=%s handler=%s hostPrep=%s\n", doc.Metadata.ID, doc.Spec.Requirements.Workload, doc.Spec.HostPrep)
		return nil
	}
	cmd := exec.Command(bin, "--approved", "run", doc.Metadata.ID)
	cmd.Dir = root
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
