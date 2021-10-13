FROM alpine:latest

RUN apk update \
    && apk add openssh \
    && apk add autossh \
    && mkdir /root/.ssh \
    && chmod 0700 /root/.ssh \
    && ssh-keygen -A \
    && sed -i s/^#PasswordAuthentication\ yes/PasswordAuthentication\ no/ /etc/ssh/sshd_config \
    && sed -i s/^GatewayPorts\ no/GatewayPorts\ yes/ /etc/ssh/sshd_config \
    && sed -i s/^AllowTcpForwarding\ no/AllowTcpForwarding\ yes/ /etc/ssh/sshd_config \
    && sed -i s/^root:!/root:*/ /etc/shadow \
    && apk add bash

COPY entrypoint.sh /
RUN chmod +x entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
