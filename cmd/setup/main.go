package main

import (
	"fmt"
	"os"

	"github.com/gin-gonic/gin"
	snapsible "github.com/ryanjyoder/snapsible/pkg"
)

func main() {

	params, err := snapsible.NewSnapctlParameterManager()
	if err != nil {
		fatal("could not get parameter manager: " + err.Error())
	}

	sshDir, _ := os.LookupEnv("SSH_DIR")
	ssh, err := snapsible.NewSshManager(sshDir)
	if err != nil {
		fatal("ssh manager err: " + err.Error())
	}

	git, err := snapsible.NewGitManager()
	if err != nil {
		fatal("could not get git manager: " + err.Error())
	}

	service, err := snapsible.NewSetuper(params, ssh, git)
	if err != nil {
		fatal("error getting service: " + err.Error())
	}

	r := gin.Default()
	snapsible.WireRoutes(r, service)

	r.RunUnix("socket")
}

func fatal(msg string) {
	fmt.Fprintf(os.Stderr, msg)
	os.Exit(1)
}
