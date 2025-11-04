FROM python:3.9

COPY ./requirements.txt /requirements.txt
RUN pip3 install -r /requirements.txt

WORKDIR /microblog

# Ajoute un user et groupe appelés microblog
RUN  useradd -ms /bin/bash -d /microblog microblog

COPY --chown=microblog:microblog ./ /microblog
# RUN chown -R microblog:microblog /microblog
USER microblog

CMD ["./boot.sh"]