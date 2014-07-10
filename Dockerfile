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
RUN apt-get -y install postgresql-client-9.3

# Install node.js environment
RUN apt-get install -y nodejs git
RUN npm install -g bower grunt-cli

# Install packages for building ruby
RUN apt-get update
RUN apt-get install -y --force-yes build-essential curl git
RUN apt-get install -y --force-yes zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get clean

# Install rbenv and ruby-build
RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build
RUN ./$HOME/.rbenv/plugins/ruby-build/install.sh
ENV PATH $HOME/.rbenv/bin:$PATH
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh # or /etc/profile
RUN echo 'eval "$(rbenv init -)"' >> .bashrc

# Install multiple versions of ruby
ENV CONFIGURE_OPTS --disable-install-doc
ADD ./versions.txt $HOME/versions.txt
RUN xargs -L 1 rbenv install < $HOME/versions.txt

# Install Bundler for each version of ruby
RUN echo 'gem: --no-rdoc --no-ri' >> $HOME/.gemrc
RUN bash -l -c 'for v in $(cat $HOME/versions.txt); do rbenv global $v; gem install bundler compass; done'

ADD service /etc/service
