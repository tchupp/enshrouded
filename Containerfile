FROM ghcr.io/goover/installers:debian AS installer

WORKDIR /home/steam

ENV STEAM_USER "anonymous"
ENV DEBIAN_FRONTEND "noninteractive"
ENV STEAM_CMD_PATH "/home/steam/steamcmd"
ENV ENSHROUDED_PATH "/home/steam/enshrouded"
ENV ENSHROUDED_CONFIG "${ENSHROUDED_PATH}/enshrouded_server.json"

RUN mkdir -p "$STEAM_CMD_PATH" \
      && curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar zxvf - -C "$STEAM_CMD_PATH" \
      && chmod +x "$STEAM_CMD_PATH/steamcmd.sh"

RUN mkdir -p "$ENSHROUDED_PATH" \
      && "$STEAM_CMD_PATH/steamcmd.sh" +@sSteamCmdForcePlatformType windows +force_install_dir "$ENSHROUDED_PATH" +login anonymous +app_update 2278520 validate +quit

FROM ghcr.io/goover/steam:proton AS runtime
LABEL org.opencontainers.image.source="https://github.com/tchupp/enshrouded"

ARG CONTAINER_GID=10000
ARG CONTAINER_UID=10000

ENV DEBIAN_FRONTEND "noninteractive"
ENV ENSHROUDED_PATH "/home/steam/enshrouded"
ENV ENSHROUDED_CONFIG "${ENSHROUDED_PATH}/enshrouded_server.json"

COPY --from=installer "$ENSHROUDED_PATH" "$ENSHROUDED_PATH"

ENV SRCDS_APPID "2278520"
ENV STEAM_DIR "/home/steam/.steam/"
ENV STEAM_CMD_PATH "/home/steam/steamcmd"
ENV STEAM_COMPAT_CLIENT_INSTALL_PATH "/home/steam/.steam/steam"
ENV STEAM_COMPAT_DATA_PATH "/home/steam/.steam/steam/steamapps/compatdata/${SRCDS_APPID}"

COPY --from=installer "$STEAM_CMD_PATH/linux32/steamclient.so" "$STEAM_DIR/sdk32/steamclient.so"
COPY --from=installer "$STEAM_CMD_PATH/linux64/steamclient.so" "$STEAM_DIR/sdk64/steamclient.so"

WORKDIR /home/steam

USER root

RUN groupadd -g $CONTAINER_GID steam \
    && useradd -g $CONTAINER_GID -u $CONTAINER_UID -m steam \
    && mkdir -p "$STEAM_COMPAT_DATA_PATH" \
    && chown -R steam:steam "$STEAM_COMPAT_DATA_PATH"

CMD ["proton", "run", "./enshrouded_server.exe"]
