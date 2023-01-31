  #!/bin/bash

  IMAGE=$1
  OPENSSH_URL=$2
  OPENSSH_SOURCE_PATH="/root/openssh/source"
  OPENSSH_PACKAGE="${OPENSSH_URL##*/}"
  OPENSSH_VERSION="${OPENSSH_PACKAGE%%.tar*}"
  IMAGE_VERSION=`echo ${IMAGE%:*}`

  #docker run -it --name openssh $IMAGE bash -c "/root/build_docker.sh $OPENSSH_URL"

  #docker cp  openssh:$OPENSSH_SOURCE_PATH/${OPENSSH_VERSION}-rpms.tar.gz /var/www/html/openssh/$IMAGE_VERSION/


  while :
  do
    docker ps | grep openssh
    if [ $? != 0 ];then
        docker cp  openssh:$OPENSSH_SOURCE_PATH/${OPENSSH_VERSION}-rpms.tar.gz /var/www/html/openssh/$IMAGE_VERSION/

           if [ $? != 0 ];then
                echo "封装失败"
                 docker rm -f openssh
             else
                echo "封装成功"
                docker rm -f openssh
           fi
           break
    fi
     sleep 1
  done