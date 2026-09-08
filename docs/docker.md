# Docker on these hosts

All four hosts import `hosts/common/optional/docker.nix`. It starts the system Docker daemon at boot and disables rootless Docker. User `ryan` belongs to the `docker` group, so normal Docker commands need no sudo.

Keep application users such as `dev`, `node`, or `plex` inside containers. Dev Containers can match their IDs to the host user for shared project folders. The system daemon runs as root; application processes need not.

## GPU access

Only cortex and brain-dongle import `hosts/common/optional/nvidia.nix`. That module enables the NVIDIA container toolkit, which generates the CDI device description. Docker on nix1 and razor does not need NVIDIA support.

Request the GPU when creating the container:

```bash
docker run --rm --device nvidia.com/gpu=all \
  nvidia/cuda:13.1.1-base-ubuntu24.04 nvidia-smi
```

`make test-docker` runs this check. On Cortex, this command saw the RTX 3080 through the system daemon as `ryan`, without sudo. Use native CDI rather than adding `--runtime=nvidia` or restoring `virtualisation.docker.enableNvidia`.

A container created without GPU access needs to be recreated with the device request; `docker exec` uses the existing container's devices.

## Check and restart

```bash
docker context ls
printenv DOCKER_HOST
docker info
ls -l /run/cdi/
systemctl status nvidia-container-toolkit-cdi-generator
```

The system socket is `unix:///var/run/docker.sock`. `make restart-docker` restarts only the system daemon. Restarting Docker can affect running workloads.

## Moving away from rootless Docker

The two daemons keep separate containers, images, and volumes. Changing the default connection does not move data. Before rebuilding another host, inspect both:

```bash
docker -H unix:///var/run/docker.sock ps -a
docker -H "unix://$XDG_RUNTIME_DIR/docker.sock" ps -a
```

Recreate any needed rootless workloads against system Docker and transfer their data with suitable ownership. Keep the old data until the move is checked.

Nix1 previously set `DOCKER_HOST` to the user socket. After rebuilding, use a fresh login or unset `DOCKER_HOST` in the current shell. Check `docker context ls` too; a saved rootless context can still select the old daemon. Restart editors that inherited the old environment.
