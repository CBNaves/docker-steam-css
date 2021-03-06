FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -y wget lib32gcc1 lib32tinfo5 unzip nginx

RUN useradd -ms /bin/bash steam
WORKDIR /home/steam

USER steam

RUN wget -O /tmp/steamcmd_linux.tar.gz http://media.steampowered.com/installer/steamcmd_linux.tar.gz && \
    tar -xvzf /tmp/steamcmd_linux.tar.gz && \
    rm /tmp/steamcmd_linux.tar.gz

# Install CSS once to speed up container startup
RUN ./steamcmd.sh +login anonymous +force_install_dir ./css +app_update 232330 validate +quit

ENV CSS_HOSTNAME  "" 
ENV CSS_PASSWORD  ""
ENV RCON_PASSWORD "" 
ENV STEAM_TOKEN   ""

EXPOSE 27015/udp
EXPOSE 27015
EXPOSE 1200
EXPOSE 27005/udp
EXPOSE 27020/udp
EXPOSE 26901/udp

ADD ./entrypoint.sh entrypoint.sh

# Support for 64-bit systems
# https://www.gehaxelt.in/blog/cs-go-missing-steam-slash-sdk32-slash-steamclient-dot-so/
RUN ln -s /home/steam/linux32/ /home/steam/.steam/sdk32

# Add Source Mods
COPY --chown=steam:steam mods/ /temp
RUN cd /home/steam/css/cstrike && \
    tar zxvf /temp/mmsource-1.10.6-linux.tar.gz && \
    tar zxvf /temp/sourcemod-1.7.3-git5275-linux.tar.gz && \
    unzip /temp/rankme.zip && \ 
    unzip /temp/bot2player.zip && \
    unzip /temp/save_scores.zip && \
    unzip /temp/enemies_left.zip && \
    unzip /temp/dropbomb1.1.zip && \
    mv /temp/mixmod.smx addons/sourcemod/plugins && \
    mv /temp/playerstacker.smx addons/sourcemod/plugins && \
    mv /temp/voicecomm.smx addons/sourcemod/plugins && \
    mv /temp/forceroundend.smx addons/sourcemod/plugins && \
    mv /temp/Cash.smx addons/sourcemod/plugins && \
    mv /temp/c4drop.smx addons/sourcemod/plugins && \
    rm /temp/*

COPY --chown=steam:steam maps/ /temp
RUN mv /temp/* /home/steam/css/cstrike/maps/

# Add default configuration files
COPY cfg/ /home/steam/css/cstrike/cfg
COPY cfg/sourcemod/mods.cfg /home/steam/css/cstrike/cfg/sourcemod/mods.cfg
COPY cfg/mapcycle.txt /home/steam/css/cstrike/mapcycle.txt
COPY cfg/motd.txt /home/steam/css/cstrike/motd.txt

CMD ./entrypoint.sh
