package pkg

import (
	"encoding/json"
	"os/exec"
)

type ParameterManager interface {
	GetParameter(name string) (string, error)
	SetParameter(name string, value string) error
	Unmarshal(key string, dest interface{}) error
	ClearParameter(name string) error
}

type SnapctlParameter struct {
}

func NewSnapctlParameterManager() (*SnapctlParameter, error) {
	return &SnapctlParameter{}, nil
}

func (snapctl *SnapctlParameter) GetParameter(name string) (string, error) {
	value, err := exec.Command("snapctl", "get", name).Output()
	return string(value), err
}

func (snapctl *SnapctlParameter) SetParameter(name string, value string) error) {
	 err := exec.Command("snapctl", "set", name+"="+value).Run()
	return err
}

func (snapctl *SnapctlParameter) Unmarshal(key string, dest interface{}) error {
	value, err := exec.Command("snapctl", "get", key).Output()
	if err != nil {
		return err
	}
	err = json.Unmarshal(value, dest)
	return err
}
func (snapctl *SnapctlParameter) ClearParameter(name string) error {
	err := exec.Command("snapctl", "set", name+"!").Run()
	return err
}
