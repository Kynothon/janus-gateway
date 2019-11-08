FROM debian:bullseye AS build

WORKDIR /usr/src

ARG MAKEFLAGS='-j8'

RUN apt update && \
	apt install -yq \
	libmicrohttpd-dev \
	libjansson-dev \
	libssl-dev \
	libsrtp2-dev \
	libsofia-sip-ua-dev \
	libglib2.0-dev \
	libopus-dev \
	libogg-dev \
	libcurl4-openssl-dev \
	liblua5.3-dev \
	libconfig-dev \
	libglib2.0-dev \
	libusrsctp-dev \
	libavutil-dev \
	libavcodec-dev \
	libavformat-dev \
	gtk-doc-tools \
	pkg-config \
	gengetopt \
	libtool \
	automake \ 
	cmake \
	make \
	git 

RUN git clone --depth 1 https://gitlab.freedesktop.org/libnice/libnice &&\
	    cd libnice && \
	    ./autogen.sh && \
	    ./configure --prefix=/usr --disable-dependency-tracking || cat config.log && \
	    make && \
	    make install

RUN git clone --depth 1 https://libwebsockets.org/repo/libwebsockets && \
	    cd libwebsockets && \
	    mkdir build && \
	    cd build && \
	    cmake -DLWS_MAX_SMP=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. && \
	    make && \
	    make install

COPY . janus-gateway

RUN cd janus-gateway && \
	    sh autogen.sh && \
	    ./configure --prefix=/opt/janus \
		--enable-post-processing \
		--enable-data-channels \
		--enable-plugin-echotest \
		--enable-plugin-recordplay \
		--enable-plugin-sip \
		--enable-plugin-videocall \
		--enable-plugin-voicemail \
		--enable-plugin-textroom \
		--enable-plugin-audiobridge \
		--enable-plugin-nosip \
		--enable-all-handlers \
		&& \
	    make && \
	    make install && \
	    make configs

FROM debian:bullseye

RUN apt update && \
	apt install -yq \
	libmicrohttpd12 \
	libjansson4 \
	libsrtp2-1 \
	libsofia-sip-ua0 \
	libglib2.0 \
	libopus0 \
	libogg0 \
	libcurl4 \
	liblua5.3 \
	libconfig9 \
	libglib2.0 \
	libavutil56 \
	libavformat58 \
	libavcodec58 \
	libusrsctp1

COPY --from=build /opt /opt
COPY --from=build /usr/lib/libnice.so.10 /usr/lib/libnice.so.10 
COPY --from=build /usr/lib/libwebsockets.so.15 /usr/lib/libwebsockets.so.15
