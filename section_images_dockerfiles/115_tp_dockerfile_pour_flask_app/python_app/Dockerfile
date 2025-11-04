FROM python:3.9

COPY ./requirements.txt /requirements.txt

RUN pip3 install -r /requirements.txt

COPY ./ /microblog

WORKDIR /microblog

# Ajoute un user et groupe appelés microblog
RUN  useradd -ms /bin/bash -d /microblog microblog -u 1002
RUN chown -R 1002:1002 ./

USER 1002