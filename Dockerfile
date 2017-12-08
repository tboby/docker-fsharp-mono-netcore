FROM dcurylo/fsharp-mono-netcore
LABEL maintainer "tboby"
RUN wget https://github.com/fsprojects/Paket/releases/download/5.125.3/paket.exe \
      && chmod a+r paket.exe && mv paket.exe /usr/local/lib/ \
      && printf '#!/bin/sh\nexec /usr/bin/mono /usr/local/lib/paket.exe "$@"' >> /usr/local/bin/paket \
      && chmod u+x /usr/local/bin/paket && \
      curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash && \
      export NVM_DIR="$HOME/.nvm" && \
      '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' && \
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
