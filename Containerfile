ARG BASE_IMAGE="quay.io/fedora/fedora-silverblue:44@sha256:7ef2aa50a10311ecbc80dd91d7858be2e7282d62578bc8d7ec9782ca42fe1ae4"

FROM scratch AS source
COPY build /build
COPY files /files

FROM ${BASE_IMAGE}
ARG VERSION="dev"
ARG SOURCE_REVISION="unknown"

RUN dnf5 config-manager setopt keepcache=1 install_weak_deps=0

RUN --mount=type=bind,from=source,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/10-base.sh && \
    /ctx/build/20-packages.sh && \
    /ctx/build/30-vscode.sh && \
    /ctx/build/40-services.sh && \
    /ctx/build/50-security.sh && \
    /ctx/build/60-desktop.sh && \
    /ctx/build/70-tuning.sh && \
    /ctx/build/80-flatpak.sh && \
    /ctx/build/90-finalize.sh

# /etc/hostname may be a runtime mount during RUN; commit it explicitly.
COPY --from=source /files/etc/hostname /etc/hostname

RUN bootc container lint --fatal-warnings

LABEL org.opencontainers.image.title="Kobold" \
      org.opencontainers.image.description="Opinionated Fedora Silverblue workstation image: hardened, tuned, minimal and developer-focused" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${SOURCE_REVISION}" \
      org.opencontainers.image.base.name="quay.io/fedora/fedora-silverblue:44"

CMD ["/sbin/init"]
