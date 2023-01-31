#!/bin/bash

#OPENSSH_URL="https://ftp.fr.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-9.1p1.tar.gz"
OPENSSH_URL=$1
X11_PATH="/root/x11-ssh-askpass-1.2.4.1.tar.gz"
OPENSSH_PACKAGE="${OPENSSH_URL##*/}"
OPENSSH_VERSION="${OPENSSH_PACKAGE%%.tar*}"
OPENSSH_SOURCE_PATH="/root/openssh/source"
RPM_BUILD_PATH="/root/rpmbuild"
IMAGE=$2
CHECK=$3


# buildrpm The buildrpm function is used to wrap the rpm package
buildrpm(){
  rpmbuild -ba xxx &> /dev/null
  #Download openssh source code package
  echo "#下载$OPENSSH_URL中..."
  wget $OPENSSH_URL -O $OPENSSH_SOURCE_PATH/$OPENSSH_VERSION.tar.gz
  if  [ $? != 0 ];then
    echo "#下载失败,请检查url: $OPENSSH_URL是否正确"
    exit 1
  else
    echo "#下载成功,开始制作rpm包...(需要点时间)"
  fi
  #[ $? != 0 ] && echo "Download $OPENSSH_PACKAGE failed" && exit 10
  tar xf $OPENSSH_SOURCE_PATH/$OPENSSH_VERSION.tar.gz -C $OPENSSH_SOURCE_PATH
  cp $OPENSSH_SOURCE_PATH/$OPENSSH_VERSION.tar.gz $RPM_BUILD_PATH/SOURCES/
  cp $X11_PATH $RPM_BUILD_PATH/SOURCES/
  cp $OPENSSH_SOURCE_PATH/$OPENSSH_VERSION/contrib/redhat/openssh.spec /root/rpmbuild/SPECS/
  chown sshd:sshd $RPM_BUILD_PATH/SPECS/openssh.spec

  sed -i -r 's/(^%(global|define) no_x11_askpass) [0-9]/\1 1/' $RPM_BUILD_PATH/SPECS/openssh.spec
  sed -i -r 's/(^%(global|define) no_gnome_askpass) [0-9]/\1 1/' $RPM_BUILD_PATH/SPECS/openssh.spec
  sed -i -r 's/(.*openssl-devel < 1.1)/#\1/' $RPM_BUILD_PATH/SPECS/openssh.spec
  sed -i -r 's/%__check_files /#&/' /usr/lib/rpm/macros

  rpmbuild -ba $RPM_BUILD_PATH/SPECS/openssh.spec &> /dev/null
  [ $? != 0 ] && echo "#制作rpm包失败, 联系管理员或重试"
  if [ `ls $RPM_BUILD_PATH/RPMS/x86_64 | wc -l` != 0 ];then
    echo "#制作rpm包成功"
  else
    echo "#制作rpm包失败"
    exit 1
  fi

  cd $RPM_BUILD_PATH/RPMS/x86_64
  tar zcf  ${OPENSSH_VERSION}-rpms.tar.gz  `ls $RPM_BUILD_PATH/RPMS/x86_64/ | grep -v debug`
  if [ $? != 0 ];then
    echo "#压缩失败"
    exit 1
  else
    echo "#压缩成功"
  fi
  mv ${OPENSSH_VERSION}-rpms.tar.gz $OPENSSH_SOURCE_PATH

}


print_info(){
  echo  "
####################################################################################################################@
# _____  _   _                                                                                                      #
#|__  / | | | |                                                                                                     #
#  / /  | |_| |                                                                                                     #
# / /_  |  _  |                                                                                                     #
#/____| |_| |_|                                                                                                     #
#博客地址: http://www.zhanghaobk.com  http://ww.zhgolang.com                                                         #
#QQ群: 706080502                                                                                                    #
#####################################################下载地址########################################################@
#                                                                                                                   #
#                                                                                                                   #
#$OPENSSH_VERSION RPM包制作完成,下载地址: http://www.zhanghaobk.com:81/openssh/$IMAGE/${OPENSSH_VERSION}-rpms.tar.gz          #
#                                                                                                                   #
#                                                                                                                   #
######################################################更新说明########################################################@
#wget http://www.zhanghaobk.com:81/openssh/$IMAGE/${OPENSSH_VERSION}-rpms.tar.gz
#tar xf ${OPENSSH_VERSION}-rpms.tar.gz
#yum -y install openssh*.rpm
#
#
##授权
#echo "PermitRootLogin yes" >> /etc/ssh/sshd_config  #允许root远程登录
#
##配置认证
#cat  > /etc/pam.d/sshd <<EOF
#
##%PAM-1.0
#auth       required     pam_sepermit.so
#auth       include      password-auth
#account    required     pam_nologin.so
#account    include      password-auth
#password   include      password-auth
### pam_selinux.so close should be the first session rule
#session    required     pam_selinux.so close
#session    required     pam_loginuid.so
### pam_selinux.so open should only be followed by sessions to be executed in the user context
#session    required     pam_selinux.so open env_params
#session    optional     pam_keyinit.so force revoke
#session    include      password-auth
#EOF
##重启服务

#chmod 0600 /etc/ssh/ssh_host_rsa_key
#chmod 0600 /etc/ssh/ssh_host_ecdsa_key
#chmod 0600 /etc/ssh/ssh_host_ed25519_key

#systemctl restart sshd && systemctl enable sshd
#
####################################################################################################################@
"
}

main(){
  if [ $CHECK -eq 1 ];then
         buildrpm
         [ $? != 0 ] && echo "Buildrpm failed" && exit 1
         print_info
  else
         print_info
  fi
}

main