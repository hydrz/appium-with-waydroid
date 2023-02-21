FROM ubuntu:20.04

# Set environment variables
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/platform-tools

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    unzip \
    weston

# Install waydroid
RUN curl https://repo.waydro.id | bash && \
    apt-get install -y waydroid

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

# Install Android SDK
RUN mkdir -p ${ANDROID_HOME} && \
    curl -L https://oos-cn.ctyunapi.cn/nan-files/commandlinetools-linux-9477386_latest.zip -o ${ANDROID_HOME}/cmdline-tools.zip && \
    unzip ${ANDROID_HOME}/cmdline-tools.zip -d ${ANDROID_HOME} && \
    rm ${ANDROID_HOME}/cmdline-tools.zip

# Add root files
COPY root/ /

# Expose ports
EXPOSE 5555

# Set the default command
CMD ["/entrypoint.sh"]