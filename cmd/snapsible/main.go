package main

import (
	"crypto/tls"
	"fmt"

	"log"
	"os"
	"os/signal"
	"syscall"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

type configs struct {
	SshUsername string
	DeviceID    string
	SecretCode  string
	MqttBroker  string
}

func onMessageReceived(client mqtt.Client, message mqtt.Message) {
	fmt.Printf("Received message on topic: %s\nMessage: %s\n", message.Topic(), message.Payload())
}

func main() {
	debug, _ := os.LookupEnv("DEBUG")
	if debug != "" {
		mqtt.DEBUG = log.New(os.Stdout, "", 0)
		mqtt.ERROR = log.New(os.Stdout, "", 0)
	}

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	cfg := &configs{}
	err := getEnvs(cfg, os.LookupEnv)
	if err != nil {
		log.Fatal(err)
	}

	server := fmt.Sprintf("tcp://%s:1883", cfg.MqttBroker)
	topic := cfg.DeviceID
	qos := 0
	clientID := cfg.DeviceID
	username := ""
	password := ""

	connOpts := mqtt.NewClientOptions().AddBroker(server).SetClientID(clientID).SetCleanSession(true)
	if username != "" {
		connOpts.SetUsername(username)
		if password != "" {
			connOpts.SetPassword(password)
		}
	}
	tlsConfig := &tls.Config{InsecureSkipVerify: true, ClientAuth: tls.NoClientCert}
	connOpts.SetTLSConfig(tlsConfig)

	connOpts.OnConnect = func(c mqtt.Client) {
		if token := c.Subscribe(topic, byte(qos), onMessageReceived); token.Wait() && token.Error() != nil {
			panic(token.Error())
		}
	}

	client := mqtt.NewClient(connOpts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatal(token.Error())
	}
	fmt.Printf("Connected to %s\n", server)

	<-c
}

func getEnvs(c *configs, lookupEnv func(string) (string, bool)) error {
	c.MqttBroker, _ = lookupEnv("MQTT_BROKER")
	if c.MqttBroker == "" {
		return fmt.Errorf("MQTT_BROKER must be set")
	}

	c.DeviceID, _ = lookupEnv("DEVICE_ID")
	if c.DeviceID == "" {
		return fmt.Errorf("DEVICE_ID must be set")
	}

	c.SshUsername, _ = lookupEnv("SSH_USERNAME")
	if c.SshUsername == "" {
		return fmt.Errorf("SSH_USERNAME must be set")
	}

	c.SecretCode, _ = lookupEnv("SECRET_CODE")
	if c.SecretCode == "" {
		return fmt.Errorf("SECRET_CODE must be set")
	}

	return nil
}
