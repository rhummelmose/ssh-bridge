# ssh-bridge

SSH into a container running in an environment where ingress is blocked.

## Requirements
* Public host
* Port of your choice (referred to as PUBLIC_HOST_PORT)
  * Open for egress from the remote environment (ie. a locked down k8s cluster)
  * Open for ingress on any public host of your choice (could be your laptop)
* Port of your choice (referred to as TUNNEL_PORT)
  * If the public host is not your local machine, it has to be open for ingress on your public host

## Steps
1. Forward the port you want to establish the tunnel on to your public host (ie. 19000 to your laptop)
2. Generate a key to use for authentication (or use one you have)
```cli
ssh-keygen -t rsa -b 4096 -f ssh-bridge-key -N ""
```
3. Set environment variables
```cli
export AUTHORIZED_KEYS_BASE64=$(cat ssh-bridge-key.pub | base64)
export PRIVATE_KEY_BASE64=$(cat ssh-bridge-key | base64)
export PUBLIC_HOST_PORT=19000 # this is the port your choose
export PUBLIC_HOST_ADDR=remote.domain.fake # name or ip of your public host
export TUNNEL_PORT=19001 # any port, used to map from public host to the remote container
```
3. Run the container in local mode on the public host
```cli
docker run \
  -e AUTHORIZED_KEYS_BASE64 \
  -p ${PUBLIC_HOST_PORT}:22 \
  -p ${TUNNEL_PORT}:${TUNNEL_PORT} \
  rhummelmose/ssh-bridge \
  --mode=local
```
4. Run the container in remote mode on the remote host
```cli
docker run \
  -e AUTHORIZED_KEYS_BASE64 \
  -e PRIVATE_KEY_BASE64 \
  -e PUBLIC_HOST_PORT \
  -e PUBLIC_HOST_ADDR \
  -e TUNNEL_PORT \
  rhummelmose/ssh-bridge \
  --mode=remote
```
5. Connect using SSH from your own command line

If the public host is your local machine:
```cli
ssh -i ssh-bridge-key -p $TUNNEL_PORT -l root localhost
```
If not:
```cli
ssh -i ssh-bridge-key -p $TUNNEL_PORT -l root $PUBLIC_HOST_ADDR
```
