FROM imduffy15/docker-frontend

ENV LANG C.UTF-8

ENV SDK_TOOLS "4333796"
ENV BUILD_TOOLS "27.0.3"
ENV TARGET_SDK "27"
ENV ANDROID_HOME "/opt/sdk"
ENV GLIBC_VERSION "2.28-r0"

ENV JAVA_VERSION 8u191
ENV JAVA_ALPINE_VERSION 8.191.12-r0

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
        echo '#!/bin/sh'; \
        echo 'set -e'; \
        echo; \
        echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
    } > /usr/local/bin/docker-java-home \
    && chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

RUN set -x \
    && apk add --no-cache \
        openjdk8="$JAVA_ALPINE_VERSION" \
    && [ "$JAVA_HOME" = "$(docker-java-home)" ]

# Install required dependencies
RUN apk add --no-cache --virtual=.build-dependencies wget unzip ca-certificates bash && \
    wget https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -O /etc/apk/keys/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk -O /tmp/glibc.apk && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk -O /tmp/glibc-bin.apk && \
    apk add --no-cache /tmp/glibc.apk /tmp/glibc-bin.apk && \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/*

# Download and extract Android Tools
RUN wget http://dl.google.com/android/repository/sdk-tools-linux-${SDK_TOOLS}.zip -O /tmp/tools.zip && \
    mkdir -p ${ANDROID_HOME} && \
    unzip /tmp/tools.zip -d ${ANDROID_HOME} && \
    rm -v /tmp/tools.zip

# Install SDK Packages
RUN mkdir -p /root/.android/ && touch /root/.android/repositories.cfg && \
    yes | ${ANDROID_HOME}/tools/bin/sdkmanager "--licenses" && \
    ${ANDROID_HOME}/tools/bin/sdkmanager "--update" && \
    ${ANDROID_HOME}/tools/bin/sdkmanager "build-tools;${BUILD_TOOLS}" "platform-tools" "platforms;android-${TARGET_SDK}" "extras;android;m2repository" "extras;google;google_play_services" "extras;google;m2repository" "emulator"

ENV GROOVY_HOME /opt/groovy
ENV GROOVY_VERSION 2.5.5

# Install groovy

RUN set -o errexit -o nounset \
    && echo "Installing build dependencies" \
    && apk add --no-cache --virtual .build-deps \
        gnupg \
    \
    && echo "Downloading Groovy" \
    && wget -qO groovy.zip "https://dist.apache.org/repos/dist/release/groovy/${GROOVY_VERSION}/distribution/apache-groovy-binary-${GROOVY_VERSION}.zip" \
    \
    && echo "Installing Groovy" \
    && unzip groovy.zip \
    && rm groovy.zip \
    && mkdir -p /opt \
    && mv "groovy-${GROOVY_VERSION}" "${GROOVY_HOME}/" \
    && ln -s "${GROOVY_HOME}/bin/grape" /usr/bin/grape \
    && ln -s "${GROOVY_HOME}/bin/groovy" /usr/bin/groovy \
    && ln -s "${GROOVY_HOME}/bin/groovyc" /usr/bin/groovyc \
    && ln -s "${GROOVY_HOME}/bin/groovyConsole" /usr/bin/groovyConsole \
    && ln -s "${GROOVY_HOME}/bin/groovydoc" /usr/bin/groovydoc \
    && ln -s "${GROOVY_HOME}/bin/groovysh" /usr/bin/groovysh \
    && ln -s "${GROOVY_HOME}/bin/java2groovy" /usr/bin/java2groovy \
    \
    && echo "Cleaning up build dependencies" \
    && apk del .build-deps

RUN npm -g install cordova cordova-icon cordova-splash
