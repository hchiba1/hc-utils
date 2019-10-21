package main

import (
	"fmt"
	"os"
	"os/exec"
)

func main() {
	execCommand()
}
func execCommand() {
	cmd := exec.Command("/home/chiba/pkg/speedtest-cli/speedtest.py", "--simple")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err := cmd.Run()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
