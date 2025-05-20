# Dockerfile
# Build image for a containerized call of the at_proxyserver binary in scratch container
# default certs included but mount /atsign/certs for certs and caroot
FROM dart:3.7.3@sha256:1d0491432892b4f7cd216dfaf8406adef5bff216adc51a024e381023d8f22ce7  AS buildimage
ENV PACKAGEDIR=packages/at_secondary_proxy
ENV HOMEDIR=/atsign
ENV WORKDIR=/app
ENV USER_ID=1024
ENV GROUP_ID=1024
SHELL ["/bin/bash", "-c"]
WORKDIR /app
COPY . .
RUN \
  set -eux ; \
  mkdir -p ${HOMEDIR} ; \
  # build at_proxyserver
  cd ${WORKDIR}/${PACKAGEDIR}; \
  dart pub get --enforce-lockfile ; \
  dart compile exe bin/main.dart -o ${HOMEDIR}/at_proxyserver ;\
  # create atsign account
  addgroup --gid $GROUP_ID atsign ; \
  useradd --system --uid $USER_ID --gid $GROUP_ID --shell /bin/bash --home $HOMEDIR atsign ;\
  cp -r ${WORKDIR}/${PACKAGEDIR}/certs /atsign ;\
  chown -R atsign:atsign $HOMEDIR 

 # Second stage of build FROM scratch
FROM scratch
ENV USER=atsign
COPY --from=buildimage /runtime/ /
COPY --from=buildimage /etc/passwd /etc/passwd
COPY --from=buildimage /etc/group /etc/group
COPY --from=buildimage --chown=1024:1024 /atsign /atsign
COPY --from=buildimage --chown=1024:1024 /atsign/at_proxyserver /atsign
WORKDIR /atsign
USER atsign
ENTRYPOINT ["/atsign/at_proxyserver"]
