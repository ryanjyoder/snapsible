package pkg

import (
	"context"
	"fmt"
)

const (
	CONFIG_KEY_GITURL = "git.url"
	CONFIG_KEY_SSH    = "ssh"

	SUGGESTION_USER_NOT_SET     = "user-not-set"
	SUGGESTION_PASSWORD_NOT_SET = "password-not-set"
	SUGGESTION_BAD_PASSWORD     = "bad-password"
)

type SshParams struct {
	User       string `json:"username"`
	Password   string `json:"password"`
	PrivateKey string `json:"private-key"`
	KeyType    string `json:"key-type"`
}

type Setuper struct {
	Params ParameterManager
	Ssh    SshManager
	Git    GitManager
}

func NewSetuper(params ParameterManager, ssh SshManager, git GitManager) (*Setuper, error) {
	return &Setuper{
		Params: params,
		Ssh:    ssh,
		Git:    git,
	}, nil
}

func (s *Setuper) DoSetup(ctx context.Context) (StatusResp, error) {
	status := StatusResp{}

	// First get configs for setting up the ssh connections
	sshConfig := SshParams{}
	err := s.Params.Unmarshal(CONFIG_KEY_SSH, &sshConfig)
	if err != nil {
		return status, err
	}
	fmt.Println("configs:", sshConfig)
	// Do the ssh connection if needed
	ok, suggestions, err := setupSshConnection(sshConfig, s.Ssh)
	if err != nil {
		return status, err
	}
	status.SshIsAccessible = ok
	status.SshSuggestions = suggestions

	// Get the git url and check if we have access
	repoURL, err := s.Params.GetParameter(ctx, CONFIG_KEY_GITURL)
	if err != nil {
		return status, err
	}
	ok, suggestions, err = setupGit(ctx, repoURL, s.Git)
	if err != nil {
		return status, err
	}
	status.GitIsAccessible = ok
	status.GitSuggestions = suggestions

	return status, nil
}

func setupSshKeys(ssh SshManager) error {

	hasKeys, err := ssh.HasSshKeys()
	if err != nil {
		return err
	}

	if hasKeys {
		return nil
	}

	err = ssh.KeyGen()
	if err != nil {
		return err
	}

	return nil
}

func setupSshConnection(cfg SshParams, ssh SshManager) (bool, []Suggestion, error) {
	if cfg.User == "" {
		return false, []Suggestion{Suggestion{
			Name:    SUGGESTION_USER_NOT_SET,
			Problem: "Ssh username not set",
			Fix:     "Set the ssh username:\n\tsnapctl set ssh.username=<username>",
		}}, nil
	}

	ok, err := ssh.CanConnect(cfg.User, "localhost")
	if err != nil || ok {
		return ok, nil, err
	}

	err = setupSshKeys(ssh)
	if err != nil {
		return false, nil, err
	}

	if cfg.Password == "" && cfg.PrivateKey == "" {
		return false, []Suggestion{Suggestion{
			Name:    SUGGESTION_PASSWORD_NOT_SET,
			Problem: "Ssh needs a password or private key to setup the connection",
			Fix:     "Set the ssh password (or private key):\n\tsnapctl set ssh.password=<password>",
		}}, nil
	}

	if cfg.Password != "" {
		err := ssh.CopyIDPassword("localhost", cfg.User, cfg.Password)
		if err != nil {
			return false, []Suggestion{Suggestion{
				Name:    SUGGESTION_BAD_PASSWORD,
				Problem: "Ssh connection fail. Bad password?",
				Fix:     "Try correcting the ssh password:\n\tsnapctl set ssh.password=<password>",
			}}, err
		}
		ok, err := ssh.CanConnect(cfg.User, "localhost")
		if ok && err == nil {
			// all went well
			return ok, nil, nil
		}

		if !ok && err == nil {
			// this shouldn't happen. ssh-copy-id worked but we still can't connect?
			return false, nil, fmt.Errorf("interal error ssh connection failed after ssh-copy-id successed")
		}

		return ok, nil, err
	}

	return false, nil, fmt.Errorf("setupSshConnection with private key not implemented")
}

func setupGit(ctx context.Context, gitURL string, git GitManager) (bool, []Suggestion, error) {
	ok, err := git.CanAccess(ctx, gitURL)
	if err != nil {
		return false, nil, err
	}

	return ok, nil, nil
}

type Suggestion struct {
	Name    string
	Problem string
	Fix     string
}
type StatusResp struct {
	SshIsAccessible bool         `json:"ssh_is_accessible"`
	SshSuggestions  []Suggestion `json:"ssh_suggestions,omitempty"`

	GitIsAccessible bool         `json:"git_is_accessible"`
	GitSuggestions  []Suggestion `json:"git_suggestions,omitempty"`
}
