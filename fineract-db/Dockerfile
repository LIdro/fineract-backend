FROM mariadb:11.4

RUN echo "[mysqld]\n\
max_allowed_packet=256M\n\
connect_timeout=60\n\
net_read_timeout=600\n\
net_write_timeout=600\n\
wait_timeout=600\n\
interactive_timeout=600\n\
max_connections=1000\n\
\n\
[client]\n\
max_allowed_packet=256M" > /etc/mysql/conf.d/custom.cnf \
    && chmod 644 /etc/mysql/conf.d/custom.cnf