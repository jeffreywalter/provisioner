FROM ruby:2.3.1

RUN apt-get update && apt-get install -y vim less nodejs
WORKDIR /srv/provisioner

CMD bash
