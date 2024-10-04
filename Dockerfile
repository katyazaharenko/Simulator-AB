FROM artifactory.mediascope.net/docker/sswt/pytorch-notebook:12.1.0-base-ubuntu22.04 as base

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apt-get update --fix-missing && \
    apt-get install -y vim && \
    apt-get clean

# RUN mkdir /app
ENV PYTHONPATH="/app"
WORKDIR /app

ARG PIPY_USER
ARG PIPY_PASSWORD

ADD ./requirements.txt .
RUN pip install pip
RUN pip install -r requirements.txt

ADD . .

FROM base AS user

ARG USERNAME=somebody
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME

RUN chown -R $USERNAME:$USERNAME /app

USER $USERNAME
