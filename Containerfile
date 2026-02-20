# Copyright (c) 2019 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG CONTAINER_IMAGE=amazonlinux:2023
ARG REMOTE_SOURCE=.
ARG REMOTE_SOURCE_DIR=/remote-source

FROM $CONTAINER_IMAGE
# ============================================================================
ARG CONTAINER_IMAGE
ARG REMOTE_SOURCE_DIR

COPY $REMOTE_SOURCE $REMOTE_SOURCE_DIR
WORKDIR $REMOTE_SOURCE_DIR/app

# Amazon Linux 2023 uses dnf, configure it for minimal docs
RUN echo "install_weak_deps=False" >> /etc/dnf/dnf.conf \
    && echo "tsflags=nodocs" >> /etc/dnf/dnf.conf

# Amazon Linux 2023 comes with Python 3.9 by default
# Install Python 3.11 and pip, along with glibc-langpack-en for locale support
RUN dnf update -y \
  && dnf install -y glibc-langpack-en python3.11 python3.11-pip \
  && dnf clean all \
  && rm -rf /var/cache/dnf \
  && rm -rf /var/lib/dnf/history.* \
  && rm -rf /var/log/*

# Upgrade pip for python3.11 to fix wheel cache for locally built wheels.
# See https://github.com/pypa/pip/issues/6852
# Note: We use python3.11 explicitly to avoid breaking dnf which depends on python3.9
RUN python3.11 -m pip install --no-cache-dir -U pip

# Install gcc for building dumb-init, then remove it to keep image small
# Use python3.11 explicitly for pip operations
RUN dnf update -y \
  && dnf install -y gcc python3.11-devel \
  && python3.11 -m pip install dumb-init --no-cache-dir -c constraints.txt \
  && dnf remove -y gcc python3.11-devel \
  && dnf clean all \
  && rm -rf /var/cache/dnf \
  && rm -rf /var/lib/dnf/history.* \
  && rm -rf /var/log/*

WORKDIR /
RUN rm -rf $REMOTE_SOURCE_DIR

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
