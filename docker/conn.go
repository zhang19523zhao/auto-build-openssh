package docker

import (
	"context"
	"fmt"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/client"
	"io"
	"log"
)

func Conn() io.Reader {
	//创建连接
	client, err := client.NewClientWithOpts(client.WithHost("unix:///var/run/docker.sock"))
	if err != nil {
		log.Println(err)
	}
	//使用连接获取容器日志，返回一个io.Reader
	logs, err := client.ContainerLogs(context.TODO(), "openssh", types.ContainerLogsOptions{
		ShowStdout: true,
		ShowStderr: true,
		Follow:     true,
	})

	return logs
}

func Eixt() bool {
	//创建一个本机docker客户端
	c, err := client.NewClientWithOpts()
	if err != nil {
		panic(err)
	}

	ctx := context.Background()

	info, err := c.Info(ctx)
	if err != nil {
		panic(err)
	}
	fmt.Println("running: ", info.ContainersRunning)
	if info.ContainersRunning == 0 {
		return true
	}
	return false
}
