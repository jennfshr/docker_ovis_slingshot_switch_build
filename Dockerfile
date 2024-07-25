FROM docker.io/debian:buster

RUN apt update \
    && apt install -y \
       autoconf \
       bison \
       build-essential \
       flex \
       less \
       libssl-dev \
       libtool \
       make \
       vim \
       pkg-config

