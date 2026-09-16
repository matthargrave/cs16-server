FROM debian:latest

ARG USER_ID=1000
ARG USER=steam
ARG HOME_DIR="/home/${USER}"

ENV STEAM_DIR "${HOME_DIR}/steam"
ENV HLDS_DIR "${HOME_DIR}/hlds"

# install dependencies
RUN apt-get update && \
    apt-get install -y lib32gcc-s1 curl lib32stdc++6 xz-utils libarchive-tools

# create user for steam
RUN useradd --uid "${USER_ID}" -g 0 -N --create-home "${USER}"
USER ${USER}

# install steamcmd
RUN mkdir -p "${STEAM_DIR}" && cd "${STEAM_DIR}" && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# FIX 1: Double-pass SteamCMD to force the legacy branch completely
RUN mkdir -p "${HLDS_DIR}" && \
    "${STEAM_DIR}/steamcmd.sh" +force_install_dir "${HLDS_DIR}" +login anonymous +app_set_config "90 mod cstrike" +app_update 90 -beta steam_legacy validate +quit && \
    "${STEAM_DIR}/steamcmd.sh" +force_install_dir "${HLDS_DIR}" +login anonymous +app_set_config "90 mod cstrike" +app_update 90 -beta steam_legacy validate +quit && \
    # see https://developer.valvesoftware.com/wiki/SteamCMD#Unable_to_locate_a_running_instance_of_Steam
    mkdir -p "/home/steam/.steam/sdk32" && \
    ln -s "${STEAM_DIR}/linux32/steamclient.so" /home/steam/.steam/sdk32/steamclient.so && \
    rm -rf /tmp/dumps && \
    chmod -R 775 /home/steam



# install rehlds
COPY --chown=steam:0 --chmod=775 ./rehlds/bin/linux32 ${HLDS_DIR}

# add custom maps
ADD --chown=steam:0 --chmod=775 maps/* "${HLDS_DIR}/cstrike/maps/"
RUN cd "${HLDS_DIR}/cstrike/maps/" && \
    ls -1 *.bsp | sed -e "s/\..*$//" > "${HLDS_DIR}/cstrike/mapcycle.txt"

# Download the legacy de_vegas.wad file missing from modern SteamCMD distributions
ADD --chown=steam:0 --chmod=775 ./de_vegas.wad "${HLDS_DIR}/cstrike/de_vegas.wad"
  

# FIX 2: Switched from Metamod-P to Metamod-R for ReHLDS stability
RUN mkdir -p "${HLDS_DIR}/cstrike/addons/metamod/dlls" && \
    curl -sqL "https://github.com/rehlds/Metamod-R/releases/download/1.3.0.149/metamod-bin-1.3.0.149.zip" | bsdtar -xf - -C "${HLDS_DIR}/cstrike/" && \
    sed -i "s/dlls\/cs.so/addons\/metamod\/metamod_i386.so/" "${HLDS_DIR}/cstrike/liblist.gam"


# install amx mod
RUN curl -sqL "https://github.com/alliedmodders/amxmodx/releases/download/1.10.0.5476/amxmodx-1.10.0-git5476-base-linux.tar.gz" | tar -C "${HLDS_DIR}/cstrike/" -zxvf - && \
    curl -sqL "https://github.com/alliedmodders/amxmodx/releases/download/1.10.0.5476/amxmodx-1.10.0-git5476-cstrike-linux.tar.gz" | tar -C "${HLDS_DIR}/cstrike/" -zxvf - && \
    curl -sqL "https://github.com/SuperCentral-Gaming-Community/AMX-Super-5.0.2/releases/download/5.0.2c/AMX-Super-5.0.2c.zip" | bsdtar -xf - -C "${HLDS_DIR}/cstrike/addons/amxmodx/" --strip-components 1 && \
    curl -qL --output "${HLDS_DIR}/cstrike/addons/amxmodx/plugins/amx_thunder.amxx"  "https://www.amxmodx.org/plcompiler_vb.cgi?file_id=39346" && \
    curl -sqL "https://github.com/rehlds/ReAPI/releases/download/5.29.0.358/reapi-bin-5.29.0.358.zip" | bsdtar -xf - -C "${HLDS_DIR}/cstrike/" && \
    mkdir -p /tmp/regamedllcs && \
    curl -sqL "https://github.com/rehlds/ReGameDLL_CS/releases/download/5.30.0.814/regamedll-bin-5.30.0.814.zip" | bsdtar -xf - -C "/tmp/regamedllcs" && \
    mv /tmp/regamedllcs/bin/linux32/cstrike/dlls/cs.so "${HLDS_DIR}/cstrike/dlls/cs.so" && \
    mv /tmp/regamedllcs/bin/linux32/cstrike/delta.lst "${HLDS_DIR}/cstrike/delta.lst" && \
    chown steam:0 "${HLDS_DIR}/cstrike/dlls/cs.so"  "${HLDS_DIR}/cstrike/delta.lst" && \
    chmod 775 "${HLDS_DIR}/cstrike/dlls/cs.so" "${HLDS_DIR}/cstrike/delta.lst" && \
    rm -rf /tmp/regamedllcs && \
    echo "linux addons/amxmodx/dlls/amxmodx_mm_i386.so" >> "${HLDS_DIR}/cstrike/addons/metamod/plugins.ini" && \
    curl -sqL "https://github.com/rehlds/ReGameDLL_CS/raw/refs/heads/master/regamedll/extra/zBot/bot_profiles.zip" | bsdtar -xf - -C "${HLDS_DIR}" && \
    rm -f "${HLDS_DIR}/cstrike/addons/amxmodx/configs/maps.ini"

# Config amx
RUN sed -i '/telemenu/s/;//' ${HLDS_DIR}/cstrike/addons/amxmodx/configs/plugins.ini && \
    sed -i '/miscstats/s/;//' ${HLDS_DIR}/cstrike/addons/amxmodx/configs/plugins.ini && \
    sed -i '/restmenu/s/;//' ${HLDS_DIR}/cstrike/addons/amxmodx/configs/plugins.ini && \
    sed -i '/stats_logging/s/;//' ${HLDS_DIR}/cstrike/addons/amxmodx/configs/plugins.ini && \
    echo "amx_super-serious.amxx" >> ${HLDS_DIR}/cstrike/addons/amxmodx/configs/plugins.ini && \
    echo "amx_super-menu.amxx" >> ${HLDS_DIR}/cstrike/addons/amxmodx/configs/plugins.ini && \
    echo "amx_super-fun.amxx" >> ${HLDS_DIR}/cstrike/addons/amxmodx/configs/plugins.ini && \
    echo "amx_super-others.amxx" >> ${HLDS_DIR}/cstrike/addons/amxmodx/configs/plugins.ini && \
    echo "amx_super-cmdmanager.amxx" >> ${HLDS_DIR}/cstrike/addons/amxmodx/configs/plugins.ini && \
    echo "amx_thunder.amxx" >> ${HLDS_DIR}/cstrike/addons/amxmodx/configs/plugins.ini && \
    echo "reapi" >> ${HLDS_DIR}/cstrike/addons/amxmodx/configs/modules.ini

# FIX 3: Ensure the actual persistent target folder exists so softlinks don't break
RUN mkdir -p /home/steam/hlds/cstrike/pdata && \
    touch /home/steam/hlds/cstrike/pdata/stats.ini \
          /home/steam/hlds/cstrike/pdata/csstats.dat \
          /home/steam/hlds/cstrike/pdata/banned.cfg \
          /home/steam/hlds/cstrike/pdata/qconsole.log \
          /home/steam/hlds/cstrike/pdata/miscstats.ini \
          /home/steam/hlds/cstrike/pdata/listip.cfg && \
    ln -sf /home/steam/hlds/cstrike/pdata/stats.ini /home/steam/hlds/cstrike/addons/amxmodx/configs/stats.ini && \
    ln -sf /home/steam/hlds/cstrike/pdata/csstats.dat /home/steam/hlds/cstrike/addons/amxmodx/data/csstats.dat && \
    ln -sf /home/steam/hlds/cstrike/pdata/banned.cfg /home/steam/hlds/cstrike/banned.cfg && \
    ln -sf /home/steam/hlds/cstrike/pdata/qconsole.log /home/steam/hlds/cstrike/qconsole.log && \
    ln -sf /home/steam/hlds/cstrike/pdata/listip.cfg /home/steam/hlds/cstrike/listip.cfg

EXPOSE 27015/TCP
EXPOSE 27015/UDP
EXPOSE 27020/UDP
EXPOSE 26900/UDP

COPY --chown=steam:0 --chmod=775 ./entrypoint.sh /

WORKDIR ${HLDS_DIR}

# FIX 4: Changed to JSON array syntax for ENTRYPOINT so it handles signals and executes properly
ENTRYPOINT ["/entrypoint.sh"]