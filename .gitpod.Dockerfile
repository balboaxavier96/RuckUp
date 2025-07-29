FROM gitpod/workspace-full-vnc:2022-07-20-05-50-58
SHELL ["/bin/bash", "-c"]

# Set environment variables
ENV ANDROID_HOME=$HOME/androidsdk \
    FLUTTER_VERSION=3.0.2-stable \
    QTWEBENGINE_DISABLE_SANDBOX=1
ENV PATH="$HOME/flutter/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

USER root

# Remove deprecated PPA and add stable Chrome repository
RUN add-apt-repository --remove ppa:ondrej/nginx-mainline || true && \
    add-apt-repository -y ppa:ondrej/nginx

RUN mkdir -p /usr/share/keyrings && \
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
    | gpg --dearmor > /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list

# Install system dependencies including Java, Chrome, GTK, fonts
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    google-chrome-stable \
    libgtk-3-dev \
    libnss3-dev \
    fonts-noto \
    fonts-noto-cjk \
    unzip \
    wget \
    curl \
    git \
    xz-utils

# Set Java 8 as default
RUN update-java-alternatives --set java-1.8.0-openjdk-amd64

USER gitpod

# Install Flutter and Android SDK
RUN wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}.tar.xz" -O - \
    | tar xJ -C $HOME && \
    _file_name="commandlinetools-linux-8092744_latest.zip" && \
    wget "https://dl.google.com/android/repository/$_file_name" && \
    unzip "$_file_name" -d $ANDROID_HOME && \
    rm -f "$_file_name" && \
    mkdir -p $ANDROID_HOME/cmdline-tools/latest && \
    mv $ANDROID_HOME/cmdline-tools/{bin,lib} $ANDROID_HOME/cmdline-tools/latest && \
    yes | sdkmanager "platform-tools" "build-tools;31.0.0" "platforms;android-31" && \
    flutter precache && \
    flutter config --enable-web && \
    flutter config --enable-linux-desktop && \
    flutter config --android-sdk $ANDROID_HOME && \
    yes | flutter doctor --android-licenses && \
    flutter doctor

