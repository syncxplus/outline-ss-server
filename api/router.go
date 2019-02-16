package api

import (
	"fmt"
	"io/ioutil"
	"math/rand"
	"strconv"
	"syscall"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"gopkg.in/yaml.v2"
)

const VERSION = "1.1.1"

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
	Keys [] accessKey
}

type resAccessKeys struct {
	AccessKeys [] accessKey `json:"accessKeys"`
	Status     bool         `json:"status"`
	Length     int          `json:"length"`
}

func Start(port int, config string) error {
	r := gin.Default()
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))
	r.GET("/version", func(c *gin.Context) {
		c.String(200, VERSION)
	})
	authorized := r.Group("/outline", gin.BasicAuth(gin.Accounts{
		"user": "123456",
	}))
	authorized.Any("", func(c *gin.Context) {
		switch c.Request.Method {
		case "GET":
			accounts, _ := ReadConfig(config)
			c.JSON(200, resAccessKeys{
				accounts.Keys,
				true,
				len(accounts.Keys),
			})
		case "DELETE":
			data, _ := yaml.Marshal(Config{})
			updateConfig(config, data)
			c.JSON(200, gin.H{
				"status": true,
			})
		default:
			c.JSON(501, gin.H{
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
		for i :=0; i < count; i++ {
			port := nextPort(start, current + i + 1)
			newKeys[i] = create(strconv.Itoa(id + i + 1), port, rate)
			accounts.Keys = append(accounts.Keys, newKeys[i])
		}
		data, _ := yaml.Marshal(accounts)
		updateConfig(config, data)
		c.JSON(200, resAccessKeys{
			newKeys,
			true,
			len(newKeys),
		})
	})
	return r.Run(":" + strconv.Itoa(port))
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

func updateConfig(file string, data []byte)  {
	ioutil.WriteFile(file, data,0777)
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
		"chacha20-ietf-poly1305",
		password,
		"chacha20-ietf-poly1305",
		password,
		rate,
		"",
		"",
	}
}

func maxId(config *Config) string {
	size := len(config.Keys)
	if size == 0 {
		return "0"
	} else {
		return config.Keys[size-1].ID
	}
}

func startPort(rate string) int {
	switch rate {
	case "10":
		return 11000
	case "20":
		return 12000
	case "80":
		return 18000
	default:
		return 10000
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
	const capacity = 1000
	port := current + 1
	if port >= (start + capacity) {
		port = start
	}
	return port
}

func password() string {
	c := []rune("abcdefghijklmnopqrstuvwxyz")
	b := make([]rune, 6)
	for i := range b {
		b[i] = c[rand.Intn(len(c))]
	}
	return string(b)
}
