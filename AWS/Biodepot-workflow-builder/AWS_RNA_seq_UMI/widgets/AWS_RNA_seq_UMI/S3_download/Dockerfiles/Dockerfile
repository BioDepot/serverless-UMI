FROM python:3.8.0-alpine3.10
ARG CLI_VERSION=1.16.272
RUN apk upgrade && apk add --no-cache nano bash zip jq
RUN pip install --upgrade pip && pip install --no-cache-dir awscli==$CLI_VERSION && \
    mkdir /root/.aws
COPY download.sh /usr/local/bin/download.sh
COPY download_files_multithread.sh /usr/local/bin/download_files_multithread.sh
COPY download_dir_multithread.sh /usr/local/bin/download_dir_multithread.sh
