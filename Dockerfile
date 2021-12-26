# Execute with docker run -d -e ENV_STRING="FOO_TEST" foo:1.0.0

FROM centos:8

RUN mkdir /workspace

COPY foo.c /workspace/foo.c

RUN \
     yum install epel-release                                         -y && \
     yum group install "Development Tools"                            -y && \
     yum install supervisor httpd                                     -y && \ 
     rm -f /var/www/html/index.html                                      && \
     g++ /workspace/foo.c -o /workspace/foo 

RUN echo -e "[program:httpd]\n\
command=/usr/sbin/httpd -DFOREGROUND\n\
process_name=%(program_name)s ; process_name expr (default %(program_name)s)\n\
numprocs=1                    ; number of processes copies to start (def 1)\n\
autostart=true                ; start at supervisord start (default: true)\n\
autorestart=true              ; retstart at unexpected quit (default: true)\n\
\n\
[program:foo@prod]\n\
command=/workspace/foo\n\
process_name=%(program_name)s ; process_name expr (default %(program_name)s)\n\
numprocs=1                    ; number of processes copies to start (def 1)\n\
autostart=true                ; start at supervisord start (default: true)\n\
autorestart=true              ; retstart at unexpected quit (default: true)\n\
stdout_logfile=/var/www/html/index.html\n"\
> /etc/supervisord.d/prod.ini

RUN echo -e '\n\
if [ -z "$ENV_STRING" ]\n\
then\n\
      echo "ENV_STRING not supplied, exiting"\n\
      exit 0\n\
fi\n\
\n\
sed -i "s/nodaemon=false/nodaemon=true/g" /etc/supervisord.conf\n\
sed -i "s/EXAMPLE_STRING/$ENV_STRING/g" /workspace/foo.c\n\
g++ /workspace/foo.c -o /workspace/foo\n\
/usr/bin/supervisord -c /etc/supervisord.conf\n'\
> /docker-entrypoint

ENTRYPOINT ["/bin/bash", "/docker-entrypoint"]
