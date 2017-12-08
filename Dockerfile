FROM dcurylo/fsharp-mono-netcore
LABEL maintainer "tboby"
# Install base dependencies
RUN apt-get update && apt-get install -y -q --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        git \
        libssl-dev \
        python \
        rsync \
        software-properties-common \
        wget \
    && rm -rf /var/lib/apt/lists/*



ENV NVM_DIR /usr/local/nvm # or ~/.nvm , depending
ENV NODE_VERSION 0.10.33

# Install nvm with node and npm
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.20.0/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/v$NODE_VERSION/bin:$PATH

RUN wget https://github.com/fsprojects/Paket/releases/download/5.125.3/paket.exe \
      && chmod a+r paket.exe && mv paket.exe /usr/local/lib/ \
      && printf '#!/bin/sh\nexec /usr/bin/mono /usr/local/lib/paket.exe "$@"' >> /usr/local/bin/paket \
      && chmod u+x /usr/local/bin/paket && \
      nvm install node && \
      npm install -g npm && \
      npm install electron-packager --global && \
      apt-get install apt-transport-https && \
      wget -nc https://dl.winehq.org/wine-builds/Release.key && \
      sudo apt-key add Release.key && \
      echo "deb https://dl.winehq.org/wine-builds/debian/ jessie main" | tee /etc/apt/sources.list.d/docker.list && \
      apt-get install -y software-properties-common python-software-properties && \
      dpkg --add-architecture i386 && \
      apt-get update && \
      apt-get install -y awscli && \
      apt-get install --install-recommends winehq-stable -y && \
WORKDIR /root
CMD ["fsharpi"]
