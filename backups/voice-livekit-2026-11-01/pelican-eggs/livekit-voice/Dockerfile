# Pelican yolk image for the JMSB voice server (LiveKit, Apache 2.0).
# Stage 1: the official LiveKit server binary, pinned.
# Stage 1b: Caddy (Apache 2.0), the optional TLS in front of LiveKit, pinned.
ARG LIVEKIT_VERSION=v1.13.9
ARG CADDY_VERSION=2.10.2
FROM livekit/livekit-server:${LIVEKIT_VERSION} AS livekit
FROM caddy:${CADDY_VERSION} AS caddy

# Stage 2: the echo test bot (echobot/), on the LiveKit Rust SDK.
FROM rust:1-bookworm AS echobot
# webrtc-sys needs clang 21+ on Linux (libwebrtc is built against Chromium's
# libc++); Debian's is older, so it comes from apt.llvm.org.
ARG CLANG_VERSION=21
RUN wget -qO /etc/apt/trusted.gpg.d/apt.llvm.org.asc https://apt.llvm.org/llvm-snapshot.gpg.key \
    && echo "deb http://apt.llvm.org/bookworm/ llvm-toolchain-bookworm-${CLANG_VERSION} main" > /etc/apt/sources.list.d/llvm.list \
    && apt-get update && apt-get install -y --no-install-recommends clang-${CLANG_VERSION} \
    && rm -rf /var/lib/apt/lists/*
ENV CC=clang-${CLANG_VERSION} CXX=clang++-${CLANG_VERSION}
WORKDIR /src
COPY echobot/ .
RUN cargo build --release --locked

# Stage 3: the Pelican debian yolk (keeps the yolk entrypoint, tini and the container user).
FROM ghcr.io/parkervcp/yolks:debian
COPY --from=livekit /livekit-server /usr/local/bin/livekit-server
COPY --from=echobot /src/target/release/echobot /usr/local/bin/echobot
COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY Caddyfile /etc/jmsb-voice/Caddyfile
COPY --chmod=755 jmsb-voice-start /usr/local/bin/jmsb-voice-start
