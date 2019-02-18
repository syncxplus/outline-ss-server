package api

import (
	"fmt"
	"io/ioutil"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"syscall"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"gopkg.in/yaml.v2"
)

const (
	version = "1.1.2"
	cipher  = "chacha20-ietf-poly1305"

	passwordLen = 6

	acceptRate10 = "10"
	acceptRate20 = "20"
	acceptRate80 = "80"

	portRange   = 1000
	portDefault = 10000
	portLimit10 = 11000
	portLimit20 = 12000
	portLimit80 = 18000
)

type accessKey struct {
	ID        string `json:"id"`
	Port      int    `json:"port"`
	Cipher    string `json:"cipher"`
	Secret    string `json:"secret"`
	Method    string `json:"method"`
	Password  string `json:"password"`
	Rate      string `json:"rate"`
	Name      string `json:"name"`
	AccessUrl string `json:"accessUrl"`
}

type Config struct {
	Keys []accessKey
}

type resAccessKeys struct {
	AccessKeys []accessKey `json:"accessKeys"`
	Status     bool        `json:"status"`
	Length     int         `json:"length"`
}

func Start(config string) error {
	r := gin.Default()
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))
	r.GET("/version", func(c *gin.Context) {
		c.String(http.StatusOK, version)
	})
	authorized := r.Group("/outline", gin.BasicAuth(gin.Accounts{
		"user": "123456",
	}))
	authorized.Any("", func(c *gin.Context) {
		switch c.Request.Method {
		case "GET":
			accounts, _ := ReadConfig(config)
			c.JSON(http.StatusOK, resAccessKeys{
				accounts.Keys,
				true,
				len(accounts.Keys),
			})
		case "DELETE":
			c.JSON(http.StatusOK, gin.H{
				"status": true,
			})
		default:
			c.JSON(http.StatusNotImplemented, gin.H{
				"message": "Unsupported method" + c.Request.Method,
			})
		}
	})
	authorized.POST("/rate/:rate/count/:count", func(c *gin.Context) {
		rate := c.Param("rate")
		count, _ := strconv.Atoi(c.Param("count"))
		newKeys := make([]accessKey, count)
		accounts, _ := ReadConfig(config)
		id, _ := strconv.Atoi(maxId(accounts))
		start := startPort(rate)
		current := maxPort(rate, start, accounts)
		for i := 0; i < count; i++ {
			port := nextPort(start, current)
			newKeys[i] = create(strconv.Itoa(id+i+1), port, rate)
			accounts.Keys = append(accounts.Keys, newKeys[i])
			current = port
		}
		data, _ := yaml.Marshal(accounts)
		updateConfig(config, data)
		c.JSON(http.StatusOK, resAccessKeys{
			newKeys,
			true,
			len(newKeys),
		})
	})
	return r.Run()
}

func ReadConfig(filename string) (*Config, error) {
	config := Config{}
	configData, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	err = yaml.Unmarshal(configData, &config)
	return &config, err
}

func updateConfig(file string, data []byte) {
	ioutil.WriteFile(file, data, os.ModePerm)
	err := syscall.Kill(syscall.Getpid(), syscall.SIGHUP)
	if err != nil {
		fmt.Println(err)
	}
}

func create(id string, port int, rate string) accessKey {
	password := password()
	return accessKey{
		id,
		port,
		cipher,
		password,
		cipher,
		password,
		rate,
		"",
		"",
	}
}

func maxId(config *Config) string {
	size := len(config.Keys)
	if size == 0 {
		return string(size)
	} else {
		return config.Keys[size-1].ID
	}
}

func startPort(rate string) int {
	switch rate {
	case acceptRate10:
		return portLimit10
	case acceptRate20:
		return portLimit20
	case acceptRate80:
		return portLimit80
	default:
		return portDefault
	}
}

func maxPort(rate string, start int, config *Config) int {
	port := start
	for _, key := range config.Keys {
		if rate == key.Rate {
			if port < key.Port {
				port = key.Port
			}
		}
	}
	return port
}

func nextPort(start, current int) int {
	port := current + 1
	if port >= (start + portRange) {
		port = start
	}
	return port
}

func password() string {
	c := []rune("abcdefghijklmnopqrstuvwxyz")
	b := make([]rune, passwordLen)
	for i := range b {
		b[i] = c[rand.Intn(len(c))]
	}
	return string(b)
}
