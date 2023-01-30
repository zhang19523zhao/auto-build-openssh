package main

import (
	"bufio"
	"bytes"
	"context"
	"fmt"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/api/types/strslice"
	"github.com/docker/docker/client"
	"github.com/gin-gonic/gin"
	"github.com/zhang19523zhao/auto-build-openssh/docker"
	"log"
	"net/http"
	"nhooyr.io/websocket"
	"nhooyr.io/websocket/wsjson"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"time"
)

func check(filepath string) (bool, error) {
	_, err := os.Stat(filepath)
	if err == nil {
		return true, nil
	}
	if os.IsNotExist(err) {
		return false, nil
	}
	return false, nil
}

func startDocker(url, image, ck string) {
	//创建一个本机docker客户端
	clt, err := client.NewClientWithOpts()
	if err != nil {
		panic(err)
	}
	ctx := context.Background()

	command := fmt.Sprintf("/root/build_docker.sh   %s %s %s", url, image, ck)

	resp, err := clt.ContainerCreate(ctx, &container.Config{
		Image: fmt.Sprintf("%s:build-openssh", image),
		Cmd:   strslice.StrSlice{"bash", "-c", command},
	}, nil, nil, nil, "openssh")
	if err != nil {
		panic(err)
	}

	//运行
	err = clt.ContainerStart(ctx, resp.ID, types.ContainerStartOptions{})
	if err != nil {
		panic(err)
	}

	go func() {
		shell := fmt.Sprintf("/root/docker/start.sh %s:build-openssh %s &", image, url)
		cmd := exec.Command("/bin/bash", "-c", shell)
		var out bytes.Buffer

		cmd.Stdout = &out
		err = cmd.Run()
		if err != nil {
			log.Fatal(err)
		}
		//fmt.Printf("%s", out.String())
	}()
}

func main() {
	r := gin.Default()
	r.LoadHTMLGlob("html/*")

	r.GET("/", func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", nil)
	})

	r.POST("/start", func(c *gin.Context) {

		image := c.PostForm("system")
		url := c.PostForm("url")

		compileRegex := regexp.MustCompile(".*/(.*)?.tar.gz")
		matchArr := compileRegex.FindStringSubmatch(url)
		version := ""
		if len(matchArr) > 0 {
			version = matchArr[len(matchArr)-1]
		}
		// openssh-7.8p1-rpms.tar.gz

		if b, _ := check(fmt.Sprintf("/var/www/html/openssh/%s/%s-rpms.tar.gz", image, version)); !b {
			ck := "1"
			startDocker(url, image, ck)
		} else {
			ck := "0"
			startDocker(url, image, ck)
		}
		c.HTML(http.StatusOK, "index.html", nil)
		c.Redirect(200, "/")

	})

	r.GET("/ws", func(c *gin.Context) {

		//创建websocker连接
		conn, err := websocket.Accept(c.Writer, c.Request, nil)
		if err != nil {
			log.Println("websocket accept error: ", err)
			return
		}
		//获取容器日志的io.Reader
		reader := docker.Conn()
		//bufio新建Reader
		r := bufio.NewReader(reader)
		for {
			//循环从reader中根据换行符读取并转换为string
			s, err := r.ReadString('\n')
			n := strings.Index(s, "#")
			//fmt.Printf("%#v", s)
			if n != -1 {
				s = s[n+1:]
			}

			if docker.Eixt() && err != nil {
				log.Println("Read err: ", err)
				time.Sleep(time.Second)
				break
			}
			//发送数据
			err = wsjson.Write(c.Request.Context(), conn, &s)
			if err != nil {
				log.Println("wsjson.writer err: ", err)
			}
		}
	})
	r.Run()
}
