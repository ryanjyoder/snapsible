package pkg

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

type SshManager interface {
	HasSshKeys() (bool, error)
	KeyGen() error
	CanConnect(usernamem string, host string) (bool, error)
	CopyIDPassword(host string, user string, password string) error
	CopyIDPrivateKey(host string, user string, key string) error
	GetPublicKey() (string, error)
}

type SshManagerShell struct {
	SshDir string
}

func NewSshManager(sshDir string) (*SshManagerShell, error) {
	return &SshManagerShell{SshDir: sshDir}, nil
}

func (ssh *SshManagerShell) HasSshKeys() (bool, error) {
	privateKeyPath := filepath.Join(ssh.SshDir, "id_rsa")
	_, err := os.Stat(privateKeyPath)
	if err == nil {
		return true, nil
	}

	if os.IsNotExist(err) {
		return false, nil
	}

	return false, err
}

func (ssh *SshManagerShell) KeyGen() error {
	idRsaPath := filepath.Join(ssh.SshDir, "id_rsa")
	return exec.Command("ssh-keygen", "-f", "id_rsa", "-t", "rsa", "-N", "", "-f", idRsaPath).Run()
}

func (ssh *SshManagerShell) CanConnect(username string, host string) (bool, error) {
	idRsaPath := filepath.Join(ssh.SshDir, "id_rsa")
	fmt.Println("ssh", "-q", "-o", "StrictHostKeyChecking=yes", "-f", "-i", idRsaPath, username+"@localhost", "exit")
	err := exec.Command("ssh", "-o", "StrictHostKeyChecking=yes", "-q", "-f", "-i", idRsaPath, username+"@localhost", "exit").Run()
	if _, ok := err.(*exec.ExitError); ok {
		return false, nil
	}
	return err == nil, err
}

func (ssh *SshManagerShell) CopyIDPassword(host string, user string, password string) error {
	idRsaPath := filepath.Join(ssh.SshDir, "id_rsa")
	fmt.Println("ssh-copy-id command: ", "sshpass", "-p"+password, "ssh-copy-id", "-i", idRsaPath, user+"@localhost")
	err := exec.Command("sshpass", "-p"+password, "ssh-copy-id", "-o", "StrictHostKeyChecking=no", "-i", idRsaPath, user+"@localhost").Run()
	if err != nil {
		return fmt.Errorf("ssh-copy-id error: %v", err)
	}
	return nil
}

func (ssh *SshManagerShell) CopyIDPrivateKey(host string, user string, key string) error {
	return fmt.Errorf("ssh.CopyIDPrivateKey not implemented")
}

func (ssh *SshManagerShell) GetPublicKey() (string, error) {
	return "", fmt.Errorf("ssh.GetPublicKey not implemented")
}
