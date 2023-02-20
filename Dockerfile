FROM kasmweb/core-ubuntu-focal:1.12.0

USER root

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
ENV INST_SCRIPTS $STARTUPDIR/install
WORKDIR $HOME

######### Customize Container Here ###########

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    unzip \
    openjdk-11-jdk-headless

# Install Android SDK
RUN mkdir -p /opt/android-sdk && \
    curl -L https://oos-cn.ctyunapi.cn/nan-files/commandlinetools-linux-9477386_latest.zip -o /opt/android-sdk/cmdline-tools.zip && \
    unzip /opt/android-sdk/cmdline-tools.zip -d /opt/android-sdk && \
    rm /opt/android-sdk/cmdline-tools.zip

# Install Android SDK components
RUN yes | /opt/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android-sdk --licenses && \
    /opt/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android-sdk "platform-tools" "platforms;android-30"

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/platform-tools

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Install waydroid
RUN curl https://repo.waydro.id | bash && \
    apt-get install -y waydroid

# Install appium
RUN npm install -g appium

# download waydroid android image
RUN mkdir -p /usr/share/waydroid-extra/images/ && \
    curl -L https://oos-cn.ctyunapi.cn/nan-files/lineage-18.1-20230212-MAINLINE-waydroid_x86_64-vendor.zip -o vendor.zip && \
    curl -L https://oos-cn.ctyunapi.cn/nan-files/lineage-18.1-20230212-VANILLA-waydroid_x86_64-system.zip -o system.zip && \
    # unzip waydroid android image 
    unzip vendor.zip -d /usr/share/waydroid-extra/images/ && \
    unzip system.zip -d /usr/share/waydroid-extra/images/ && \
    # remove waydroid android image zip
    rm vendor.zip && \
    rm system.zip

RUN apt install -y dkms

RUN waydroid init

# Add root files
COPY root/ /

# Expose ports
EXPOSE 4723

######### End Customizations ###########

RUN chown 1000:0 $HOME

ENV HOME /home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

USER 1000