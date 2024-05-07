FROM ubuntu:22.04
MAINTAINER Butopêa <alex@butopea.com>

# ENV variables
ENV DEBIAN_FRONTEND noninteractive
ENV TZ "Europe/Budapest"
ENV CUPSADMIN admin
ENV CUPSPASSWORD password
ENV PRINTNODE_HOSTNAME docker


LABEL org.opencontainers.image.source="https://github.com/butopea/printnode"
LABEL org.opencontainers.image.description="Printnode / CUPS Printer Server"
LABEL org.opencontainers.image.author="Alex Schikalow <alex@butopea.com>"
LABEL org.opencontainers.image.url="https://github.com/butopea/printnode-docker/blob/main/README.md"


# Install dependencies
RUN apt-get update -qq  && apt-get upgrade -qqy \
    && apt-get install -qqy \
    apt-utils \
    curl \
    usbutils \
    cups \
    cups-filters \
    printer-driver-all \
    printer-driver-cups-pdf \
    printer-driver-foo2zjs \
    foomatic-db-compressed-ppds \
    openprinting-ppds \
    hpijs-ppds \
    hp-ppd \
    hplip \
    avahi-daemon \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Setup PrintNode
RUN mkdir /usr/local/PrintNode \
    && curl -s https://dl.printnode.com/client/printnode/4.27.17/PrintNode-4.27.17-ubuntu-22.04-x86_64.tar.gz -o /tmp/printnode.tar.gz \
    && echo "d767740faf8f9b6977ad7b8fe9201dfb225c6378 /tmp/printnode.tar.gz" | sha1sum -c - \
    && tar -xzf /tmp/printnode.tar.gz -C /usr/local/PrintNode --strip-components 1 \
    && rm /tmp/printnode.tar.gz

# Remove backends that aren't needed
RUN rm /usr/lib/cups/backend/parallel \
     && rm /usr/lib/cups/backend/serial \
     && rm /usr/lib/cups/backend/cups-brf

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
    sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
    echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf

# back up cups configs in case users do not add their own
RUN cp -rp /etc/cups /etc/cups-bak
VOLUME [ "/etc/cups" ]

# Cups ports
EXPOSE 631
EXPOSE 5353/udp
# Printnode Webinterface port
EXPOSE 8888

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]