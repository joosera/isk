FROM ruby:2.3.0-slim

MAINTAINER Niko Vähäsarja <deram@iki.fi>


RUN apt-get update && apt-get install -qq -y --fix-missing --no-install-recommends \
	build-essential \
	git \
	imagemagick \
	libpq-dev \
	librrd4 \
	librrd-dev \
	nodejs \
	rrdtool

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list.d/jessie-backports.list
RUN apt-get update && apt-get -t jessie-backports install -qq -y --fix-missing --no-install-recommends \
	inkscape

ENV INSTALL_PATH /isk
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH

RUN gem install bundler
COPY Gemfile* ./
RUN bundle install

#COPY . .

#RUN bundle exec rake RAILS_ENV=production DATABASE_URL=postgresql://user:pass@127.0.0.1/dbname SECRET_TOKEN=pickasecuretoken assets:precompile

CMD ["/isk/docker-start.sh"]

