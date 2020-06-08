#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
#set -euo pipefail

TASK=$1
IMAGE=$2
KUBE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

test() {
  echo $KUBE_ROOT
  echo $(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
}

ssl() {
  # Generate keys into a temporary directory.
  echo "Generating TLS keys ..."
  "${basedir}/generate-keys.sh" "$keydir"

  chmod 0700 "$key_dir"
  cd "$key_dir"
  # Generate the CA cert and private key
  openssl req -nodes -new -x509 -keyout ca.key -out ca.crt -subj "/CN=Admission Webhook CA"
  # Generate the private key for the webhook server
  openssl genrsa -out webhook-server-tls.key 2048
  # Generate a Certificate Signing Request (CSR) for the private key, and sign it with the private key of the CA.
  openssl req -new -key webhook-server-tls.key -subj "/CN=admission-webhook.default.svc" |
    openssl x509 -req -CA ca.crt -CAkey ca.key -CAcreateserial -out webhook-server-tls.crt

  # Read the PEM-encoded CA certificate, base64 encode it, and replace the `${CA_PEM_B64}` placeholder in the YAML
  # template with it. Then, create the Kubernetes resources.
  ca_pem_b64="$(openssl base64 -A <"${keydir}/ca.crt")"
}

# Returns baseimage need to used in Dockerfile for any given architecture
getBaseImage() {
  os_arch=$1
  grep "${os_arch}=" BASEIMAGE | cut -d= -f2
}

# This function will build the docker images
build() {
  image=$1
  arch="amd64"
  os_name="linux"
  TAG=$(<VERSION)
  BASEIMAGE=$(getBaseImage ${arch})
  echo "Building image for ${image} OS/ARCH: ${BASEIMAGE}..."
  docker build --pull -t "${REGISTRY}/${image}:${TAG}-${os_name}-${arch}" --build-arg BASEIMAGE="${BASEIMAGE}" .
}

bin() {
  # shellcheck disable=SC2068
  for SRC in $@; do
    #    TARGET:/Users/jason/go/src/serverside-test/webhook
    #    KUBE_ROOT:/Users/jason/go/src
    docker run --rm -it -v ${TARGET}:${TARGET}:Z -v ${KUBE_ROOT}:/goarch/src/k8s.io/kubernetes:Z \
      golang:${GOLANG_VERSION} \
      /bin/bash -c \
                cd /go/src/k8s.io/kubernetes/serverside-test/${SRC_DIR} && \
                CGO_ENABLED=0 GOARM=${GOARM} GOOS=${GOOS} GOARCH=${ARCH} go build -a -installsuffix cgo --ldflags '-w' -o ${TARGET}/${SRC} ./$(dirname ${SRC})
    #    GOLANG_VERSION:latest
    #    SRC_DIR:webhook
    #    GOARM:7
    #    ARCH:amd64

  done
}
shift

eval ${TASK} "$@"
