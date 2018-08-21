FROM microsoft/dotnet:2.1.400-sdk-stretch
ENV MONO_THREADS_PER_CPU 50
RUN MONO_VERSION=5.12.0.226 && \
    FSHARP_VERSION=10.0.2 && \
    FSHARP_BASENAME=fsharp-$FSHARP_VERSION && \
    FSHARP_ARCHIVE=$FSHARP_VERSION.tar.gz && \
    FSHARP_ARCHIVE_URL=https://github.com/fsharp/fsharp/archive/$FSHARP_VERSION.tar.gz && \
    export GNUPGHOME="$(mktemp -d)" && \
    apt-get update && apt-get --no-install-recommends install -y gnupg dirmngr && \
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/debian stretch/snapshots/$MONO_VERSION main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
    apt-get install -y apt-transport-https && \
    apt-get update -y && \
    apt-get --no-install-recommends install -y pkg-config make nuget mono-devel msbuild ca-certificates-mono locales && \
    rm -rf /var/lib/apt/lists/* && \
    echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    printf "namespace a { class b { public static void Main(string[] args) { new System.Net.WebClient().DownloadFile(\"%s\", \"%s\");}}}" $FSHARP_ARCHIVE_URL $FSHARP_ARCHIVE > download-fsharp.cs && \
    mcs download-fsharp.cs && mono download-fsharp.exe && rm download-fsharp.exe download-fsharp.cs && \
    tar xf $FSHARP_ARCHIVE && \
    cd $FSHARP_BASENAME && \
    make && \
    make install && \
    cd ~ && \
    rm -rf /tmp/src /tmp/NuGetScratch ~/.nuget ~/.config ~/.local "$GNUPGHOME" && \
    apt-get purge -y make gnupg dirmngr && \
    apt-get clean
WORKDIR /root
ENV FrameworkPathOverride /usr/lib/mono/4.7.1-api/
CMD ["fsharpi"]
LABEL maintainer "tboby"
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node
  
RUN apt-get update && \
  apt-get install -y xz-utils gnupg

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
  ; do \
    gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$key" ; \
  done

ENV NODE_VERSION 9.2.1

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs
  
ENV YARN_VERSION 1.3.2

RUN set -ex \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
  done \
  && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt/yarn \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/yarn --strip-components=1 \
  && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz

RUN yarn global add npm

RUN wget https://github.com/fsprojects/Paket/releases/download/5.176.0/paket.bootstrapper.exe \
      && mv ./paket.bootstrapper.exe paket.exe \
      && chmod a+r paket.exe && mv paket.exe /usr/local/lib/ \
      && printf '#!/bin/sh\nexec /usr/bin/mono /usr/local/lib/paket.exe "$@"' >> /usr/local/bin/paket \
      && chmod u+x /usr/local/bin/paket && \
      npm install electron-packager --global && \
      apt-get install apt-transport-https && \
      wget -nc https://dl.winehq.org/wine-builds/Release.key && \
      apt-key add Release.key && \
      echo "deb https://dl.winehq.org/wine-builds/debian/ stretch main" | tee /etc/apt/sources.list.d/docker.list && \
      apt-get install -y software-properties-common && \
      dpkg --add-architecture i386 && \
      apt-get update && \
      apt-get install -y awscli && \
      apt-get install --install-recommends wine-stable winehq-stable -y
WORKDIR /root
CMD ["fsharpi"]
