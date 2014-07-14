FROM sjoerdmulder/java7

# This will use the 1.0.0 release
RUN wget -O /usr/local/bin/docker https://get.docker.io/builds/Linux/x86_64/docker-1.0.0
RUN chmod +x /usr/local/bin/docker
ADD 10_wrapdocker.sh /etc/my_init.d/10_wrapdocker.sh
RUN groupadd docker

RUN apt-get update
RUN apt-get install -y unzip iptables lxc build-essential fontconfig

ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8
ENV AGENT_DIR  /opt/buildAgent

# Check install and environment
ADD 00_checkinstall.sh /etc/my_init.d/00_checkinstall.sh

RUN adduser --disabled-password --gecos "" teamcity
RUN sed -i -e "s/%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/" /etc/sudoers
RUN usermod -a -G docker,sudo teamcity

EXPOSE 9090

VOLUME /var/lib/docker

# Install postgres, ruby and node.js build repositories
RUN apt-add-repository ppa:chris-lea/node.js
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main\n" > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update

# Install postgres-client
RUN apt-get -y install postgresql-client-9.3 libpq-dev

# Install node.js environment
RUN apt-get install -y nodejs git
RUN npm install -g bower grunt-cli

# Install packages for building ruby
RUN apt-get update
RUN apt-get install -y --force-yes build-essential curl git
RUN apt-get install -y --force-yes openssl libreadline-dev curl zlib1g zlib1g-dev libssl-dev libyaml-dev libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison libcurl4-openssl-dev
RUN apt-get clean

USER teamcity
ENV HOME /home/teamcity
# Install rbenv and ruby-build
RUN git clone https://github.com/sstephenson/rbenv.git /home/teamcity/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /home/teamcity/.rbenv/plugins/ruby-build
ENV PATH /home/teamcity/.rbenv/shims:/home/teamcity/.rbenv/bin:$PATH
RUN eval "$(rbenv init -)"
RUN echo 'export PATH="/home/teamcity/.rbenv/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(rbenv init -)"' >> ~/.bashrc


# Install multiple versions of ruby
ENV CONFIGURE_OPTS --disable-install-doc
RUN curl -fsSL https://gist.github.com/mislav/a18b9d7f0dc5b9efc162.txt | rbenv install --patch 2.1.1
RUN rbenv install 2.1.2

# Install Bundler for each version of ruby
RUN echo 'gem: --no-rdoc --no-ri' >> /home/teamcity/.gemrc
RUN bash -l -c 'for v in $(rbenv versions); do rbenv global $v; gem install bundler pg compass saas; done'

USER root
ENV HOME /root
RUN chown -R teamcity:teamcity /home/teamcity

RUN npm install -g bower grunt-cli protractor
RUN apt-get install -y --force-yes imagemagick

ADD service /etc/service


