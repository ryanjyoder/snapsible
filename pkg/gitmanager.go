package pkg

import (
	"context"
	"fmt"
	"os"
	"os/exec"
)

type GitManager interface {
	CanAccess(ctx context.Context, url string) (bool, error)
}

// GitManagerShell usaages the shell to check access to a git repo.
type GitManagerShell struct {
}

func NewGitManager() (*GitManagerShell, error) {
	return &GitManagerShell{}, nil
}

func (git *GitManagerShell) CanAccess(ctx context.Context, url string) (bool, error) {
	// TODO inspect error type
	cmd := exec.Command("git", "ls-remote", "-h", url)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()

	fmt.Println("git", "ls-remote", "-h", url, "\n", err)
	return err == nil, nil
}
