FROM nvidia/cuda:12.2.2-base-ubuntu22.04
LABEL maintainer="jshyeon"
LABEL description="jshyeon ML server"
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y build-essential python3 python3-pip nano vim net-tools sudo openssh-server wget bzip2

# SSH 서버 설정
RUN mkdir /var/run/sshd

# SSH 포트 8888으로 변경 및 비밀번호 인증 설정
RUN sed -i 's/#Port 22/Port 8888/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/PasswordAuthentication no/#PasswordAuthentication no/' /etc/ssh/sshd_config
RUN echo "PermitRootLogin no" >> /etc/ssh/sshd_config

CMD service ssh restart && /bin/bash

RUN useradd -m gpp && echo "gpp:gppgppgpp" | chpasswd
RUN usermod -aG sudo gpp
RUN echo "gpp ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/gpp

RUN chsh -s /bin/bash gpp

USER gpp
WORKDIR /home/gpp

# Miniconda 설치
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /home/gpp/miniconda.sh && \
    bash /home/gpp/miniconda.sh -b -p /home/gpp/miniconda && \
    rm /home/gpp/miniconda.sh

# 환경변수 설정
ENV PATH=/home/gpp/miniconda/bin:$PATH

# conda 업데이트
RUN conda update -n base -c defaults conda

# conda base 환경에서 pytorch, transformers 설치
RUN conda install -y pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch  -c nvidia && \
    conda install -y conda-forge::transformers

# 기본 쉘을 bash로 설정
CMD ["/bin/bash"]

USER root
RUN service ssh start

USER gpp
WORKDIR /home/gpp

RUN echo "sudo service ssh start" >> .bashrc

# docker run --name ml-server -d --restart always -p 8888:8888 --gpus=all -it jshyeon-ml-server /bin/bash
