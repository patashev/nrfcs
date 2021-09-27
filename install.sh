#!/bin/bash

if [ `whoami` != root ]; then
    echo Please run this script as root or using sudo
    exit
fi

if ! [ -x "$(command -v git)" ]; then
  echo 'Error: git is not installed.' >&2
  exec apt install git -y
  if ![ -x "$(command --version gcc)" ]; then
    echo 'Error: gcc is not installed.' >&2
    exec apt install build-essential -y
  fi
fi


function cloneResources()
{
    declare -a arr=(
        "https://github.com/arut/nginx-rtmp-module.git" 
        "git://git.openssl.org/openssl.git"
        "https://github.com/kaltura/nginx-vod-module.git"
        "https://github.com/vozlt/nginx-module-vts.git"
        "https://github.com/apache/incubator-pagespeed-ngx.git"
        );
    for i in "${arr[@]}"
    do
        cd resources/
        git clone $i
        cd ../
    done

}


function makeRepositories()
{
    declare -a arr=(
        "$1/pcre2-10.37"
        "$1/zlib-1.2.11"
        );
    for i in "${arr[@]}"
    do
        cd $i/
        ./configure
        make
        make install
        cd "$1"
    done

}

function makeNginx()
{
    cd "$1/nginx-1.19.2"
    ./configure --with-http_ssl_module --with-http_geoip_module --prefix=$1/nginx \
    --with-file-aio --with-http_stub_status_module --add-module=$1/nginx-rtmp-module \
    --add-module=$1/nginx-vod-module --with-http_xslt_module --with-http_ssl_module \
    --add-module=$1/nginx-module-vts --add-module=$1/incubator-pagespeed-ngx \
    --with-http_xslt_module --with-http_secure_link_module --with-http_realip_module \
    --with-http_gunzip_module --with-ipv6 --with-http_gzip_static_module
}


function downloadResources () 
{
    export RESOURCES=resources;
    declare -a arr=(
        "https://ftp.pcre.org/pub/pcre/pcre2-10.37.tar.gz"
        "http://zlib.net/zlib-1.2.11.tar.gz"
        "https://nginx.org/download/nginx-1.19.2.tar.gz"
        );
    for i in "${arr[@]}"
    do
        wget $i --directory-prefix="$RESOURCES" -O $RESOURCES/${i##*/}
        wget --quiet --spider $i
        if [ $? -eq 0 ] ; then    
            wget $i --directory-prefix="$RESOURCES" -O $RESOURCES/${i##*/}
        fi
    done
    FILES="$RESOURCES/*"
    for f in $FILES
    do
        tar -xvf $f --directory "$RESOURCES/";
    done
    rm $RESOURCES/*.gz
}


function setInstallPath()
{
    export WORKD=$( pwd );
}


if ! [ -x "$(which g++)" ];
then
    apt-cache show "gcc"
    sudo apt install gcc -y
fi

if ! [ -x "$(ls -a | grep resources)" ]; then
    setInstallPath
    export WORKDIR=$WORKD
    echo $WORKDIR
    mkdir resources
    downloadResources
    cloneResources
    makeRepositories "$WORKDIR/resources"
    makeNginx "$WORKDIR/resources"
else
    setInstallPath
    export WORKDIR=$WORKD
    downloadResources
    cloneResources
    makeRepositories "$WORKDIR/resources"
    makeNginx "$WORKDIR/resources"
fi

