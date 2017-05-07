
if [ $# != 3 ];then 
	echo "usage: ./deploy binaryname exposeport Linuxversion"
	exit
fi

echo 'FROM '$3'

RUN sed -i "s/http:\/\/archive.ubuntu.com/http:\/\/mirrors.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list
RUN apt-get update && apt-get -y dist-upgrade
RUN apt-get install -y lib32z1 xinetd

RUN useradd -m ctf

COPY ./bin/ /home/ctf/
COPY ./ctf.xinetd /etc/xinetd.d/ctf
COPY ./start.sh /start.sh
RUN echo "Blocked by ctf_xinetd" > /etc/banner_fail

RUN chmod +x /start.sh
RUN chown -R root:ctf /home/ctf
RUN chmod -R 750 /home/ctf
RUN chmod 740 /home/ctf/flag

RUN cp -R /lib* /home/ctf
RUN cp -R /usr/lib* /home/ctf

RUN mkdir /home/ctf/dev
RUN mknod /home/ctf/dev/null c 1 3
RUN mknod /home/ctf/dev/zero c 1 5
RUN mknod /home/ctf/dev/random c 1 8
RUN mknod /home/ctf/dev/urandom c 1 9
RUN chmod 666 /home/ctf/dev/*

RUN mkdir /home/ctf/bin
RUN cp /bin/sh /home/ctf/bin
RUN cp /bin/ls /home/ctf/bin
RUN cp /bin/cat /home/ctf/bin

WORKDIR /home/ctf

CMD ["/start.sh"]

EXPOSE 9999' > ctf_xinetd/Dockerfile



echo "service ctf
{
    disable = no
    socket_type = stream
    protocol    = tcp
    wait        = no
    user        = root
    type        = UNLISTED
    port        = 9999
    bind        = 0.0.0.0
    server      = /usr/sbin/chroot
    # replace helloworld to your program
    server_args = --userspec=1000:1000 /home/ctf ./$1
    banner_fail = /etc/banner_fail
    # safety options
    per_source	= 10 # the maximum instances of this service per source IP address
    rlimit_cpu	= 20 # the maximum number of CPU seconds that the service may use
    #rlimit_as  = 1024M # the Address Space resource limit for the service
    #access_times = 2:00-9:00 12:00-24:00
}" > ctf_xinetd/ctf.xinetd

rm ctf_xinetd/bin/*
echo -e `echo -e "ctf{\c";head /dev/urandom | md5sum | head -c 27;echo -e "}\c"` > ctf_xinetd/bin/flag
cp $1/$1 ctf_xinetd/bin/
cd ctf_xinetd
docker build -t "$1" .
docker run -d -p "0.0.0.0:$2:9999" -h "$1" --name="$1" $1
cd ..
docker exec -t $1 cat lib/x86_64-linux-gnu/libc.so.6 > lib/libc.so.6.64
docker exec -t $1 cat lib32/libc.so.6 > lib/libc.so.6.32

