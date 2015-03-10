Name:		chorus
Version:	%{?version}	
Release:	%{?release}
Summary:	spec file for chorus-apine	

Group:		Alpine Data Labs
License:	GPL
URL:		https://github.com/Chorus/chorus
Source0:	%{name}.logrotate
#BuildArch: 	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}
Prefix:		/usr/local
#BuildRequires:	
Requires:	logrotate
Autoreq :	no

%define appdir	%{prefix}/%{name}
%define releases	%{appdir}/releases/%{version}-%{release}
%define shared		%{appdir}/shared
%define data	/data/%{name}
%description


%prep
#%%setup -q


%build
#%%configure
#make %{?_smp_mflags}
pushd %{name}
echo `pwd`
export WORKSPACE=`pwd`
export RAILS_ENV=packaging

if [ "$HOSTNAME" = chorus-ci ]; then
  export GPDB_HOST=chorus-gpdb-ci
  export ORACLE_HOST=chorus-oracle
  export HAWQ_HOST=chorus-gphd20-2
fi
export JRUBY_OPTS="--client -J-Xmx1024m -J-Xms512m -J-Xmn128m -Xcext.enabled=true"
export PATH="$HOME/phantomjs/bin:$HOME/node/bin:$HOME/.rbenv/bin:$PATH"


if [[ -z "$POSTGRES_HOME" ]]; then
  export POSTGRES_HOME="/usr/pgsql-9.2"
fi
./install-ruby.sh
eval "$(rbenv init - --no-rehash)"
#rbenv shell `cat .rbenv-version`
rbenv shell `cat .ruby-version`
gem list bundler | grep bundler || gem install bundler
echo `pwd`
bundle install --binstubs=b/ || (echo "bundler failed!!!!!!!!" && exit 1)

mkdir -p tmp/pids
rm -f tmp/fixture_builder*.yml tmp/instance_integration_file_versions*.yml tmp/GPDB_HOST_STALE

cp config/chorus.properties.example config/chorus.properties

rm -f postgres && ln -s $POSTGRES_HOME postgres

mkdir -p $WORKSPACE/lib/libraries
cp ~/ojdbc6.jar $WORKSPACE/lib/libraries/ojdbc6.jar
cp ~/tdgssconfig.jar $WORKSPACE/lib/libraries/tdgssconfig.jar
cp ~/terajdbc4.jar $WORKSPACE/lib/libraries/terajdbc4.jar

b/rake development:generate_database_yml development:generate_secret_token development:generate_secret_key package:prepare_hdfs_jar db:drop db:create db:migrate --trace > "$WORKSPACE/bundle.log"
echo "checking for an alpine package"
if [[ $(ls vendor/alpine/*.sh 2> /dev/null | wc -l) != "0" ]]; then
    echo "packaging with alpine"
    chmod +x vendor/alpine/*.sh
fi

rm -fr .bundle

IGNORE_DIRTY=true RAILS_ENV=packaging bundle exec rake package:installer --trace
popd	
%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{appdir}
mkdir -p $RPM_BUILD_ROOT/%{releases}
mkdir -p $RPM_BUILD_ROOT/%{releases}/script
mkdir -p $RPM_BUILD_ROOT/%{releases}/solr
mkdir -p $RPM_BUILD_ROOT/%{data}
mkdir -p $RPM_BUILD_ROOT/%{data}/db
mkdir -p $RPM_BUILD_ROOT/%{data}/log
mkdir -p $RPM_BUILD_ROOT/%{data}/solr/data
mkdir -p $RPM_BUILD_ROOT/%{data}/system

pushd %{name}
cp -R bin/ $RPM_BUILD_ROOT/%{releases}
cp -R app/ $RPM_BUILD_ROOT/%{releases}
cp -R config/ $RPM_BUILD_ROOT/%{releases}
cp -R db/ $RPM_BUILD_ROOT/%{releases}
cp -R doc/ $RPM_BUILD_ROOT/%{releases}
cp -R lib/ $RPM_BUILD_ROOT/%{releases}
cp -R packaging/ $RPM_BUILD_ROOT/%{releases}
cp -R public/ $RPM_BUILD_ROOT/%{releases}
cp -R script/rails $RPM_BUILD_ROOT/%{releases}/script
cp -R solr/conf $RPM_BUILD_ROOT/%{releases}/solr
cp -R vendor/ $RPM_BUILD_ROOT/%{releases}
cp -R WEB-INF/ $RPM_BUILD_ROOT/%{releases}
cp -R Gemfile $RPM_BUILD_ROOT/%{releases}
cp -R Gemfile.lock $RPM_BUILD_ROOT/%{releases}
cp -R Gemfile-packaging $RPM_BUILD_ROOT/%{releases}
cp -R Gemfile-packaging.lock $RPM_BUILD_ROOT/%{releases}
cp -R README.md $RPM_BUILD_ROOT/%{releases}
cp -R Rakefile $RPM_BUILD_ROOT/%{releases}
cp -R config.ru $RPM_BUILD_ROOT/%{releases}
cp -R version.rb $RPM_BUILD_ROOT/%{releases}
echo %{version}-%{release} > $RPM_BUILD_ROOT/%{releases}/version_build 
cp -R .bundle/ $RPM_BUILD_ROOT/%{releases}

rm -rf $RPM_BUILD_ROOT/%{releases}/config/secret.key
rm -rf $RPM_BUILD_ROOT/%{releases}/config/test.crt
rm -rf $RPM_BUILD_ROOT/%{releases}/config/test.key
rm -rf $RPM_BUILD_ROOT/%{releases}/config/sunspot.yml
rm -rf $RPM_BUILD_ROOT/%{releases}/config/database.yml
rm -rf $RPM_BUILD_ROOT/%{releases}/config/database.yml.example
rm -rf $RPM_BUILD_ROOT/%{releases}/config/deploy.yml
rm -rf $RPM_BUILD_ROOT/%{releases}/config/jetpack.yml
rm -rf $RPM_BUILD_ROOT/%{releases}/config/jshint.json
rm -rf $RPM_BUILD_ROOT/%{releases}/config/license_finder.yml
rm -rf $RPM_BUILD_ROOT/%{releases}/config/license_template.default.yml
rm -rf $RPM_BUILD_ROOT/%{releases}/lib/libraries

popd
#make install DESTDIR=%{buildroot}
%clean
rm -rf "$RPM_BUILD_ROOT"
%pre
if [[ (-f /etc/redhat-release) && (`uname -a | grep x86_64` != "") ]]; then
    OS_VERSION="RedHat"
    VERSION_ID=`cat /etc/redhat-release |awk '{print $3}'|cut -d'.' -f1-1`
elif [[ (-f /etc/SuSE-release) && (`cat /etc/SuSE-release | grep x86_64` != "") ]]; then
    OS_VERSION="SuSE"
    VERSION_ID=`cat /etc/SuSE-release|grep SUSE|awk '{print $5}'`
fi
if [[ !($OS_VERSION == "RedHat" && ($VERSION_ID == "5" || $VERSION_ID == "6"))
	&& !($OS_VERSION == "SuSE" && $VERSION_ID == "11") ]]; then
	echo "Operation System not supported, only support RedHat 5~6 and SuSE 11 x86_64"
	exit -1
fi
%post
function log() {
  su - chorus -c "echo '$1' 2>&1 |tee -a %{appdir}/install.log"
}
function error_exit() {
  if [[ !`echo "$?"` = "0" ]]; then
	echo "error happend! erase the rpm"
	rpm -e %{name}-%{version}-%{release}
	exit -1
  fi
}
log "add chorus user if not exits"
useradd chorus >> %{appdir}/install.log 2>&1
groupadd chorus >> %{appdir}/install.log 2>&1
log "construct shared structure in %{shared}"
su - chorus -c "mkdir -p %{shared}"
error_exit
su - chorus -c "mkdir -p %{shared}/demo_data"
error_exit
su - chorus -c "mkdir -p %{shared}/libraries"
error_exit
su - chorus -c "mkdir -p %{shared}/solr"
error_exit
su - chorus -c "mkdir -p %{shared}/tmp"
error_exit
if [[ ! -f %{shared}/database.yml ]]; then
	su - chorus -c "cp %{releases}/packaging/database.yml.example  %{shared}/database.yml"
	error_exit
fi
if [[ ! -f %{shared}/sunspot.yml ]]; then
	su - chorus -c "cp %{releases}/packaging/sunspot.yml.example  %{shared}/sunspot.yml"
	error_exit
fi
if [[ ! -f %{shared}/chorus.properties ]]; then
	su - chorus -c "cp %{releases}/config/chorus.defaults.properties  %{shared}/chorus.properties"
	error_exit
	su - chorus -c "chmod 0600 %{shared}/chorus.properties"
	error_exit
fi
su - chorus -c "cp %{releases}/config/chorus.defaults.properties  %{shared}/chorus.properties.example"
error_exit
su - chorus -c "cp %{releases}/config/chorus.license.default  %{shared}/chorus.license.default"
error_exit

if [[ ! -f %{shared}/chorus.license ]]; then
	su - chorus -c "cp %{releases}/config/chorus.license.default  %{shared}/chorus.license"
	error_exit
	su - chorus -c "chmod 0600 %{shared}/chorus.license" 
	error_exit
fi
log "Linking shared configuration files to %{releases}/config"
su - chorus -c "ln -sf %{shared}/chorus.properties %{releases}/config/chorus.properties"
error_exit
su - chorus -c "ln -sf %{shared}/chorus.license %{releases}/config/chorus.license"
error_exit
su - chorus -c "ln -sf %{shared}/database.yml %{releases}/config/database.yml"
error_exit
su - chorus -c "ln -sf %{shared}/sunspot.yml %{releases}/config/sunspot.yml"
error_exit
rm -rf %{releases}/demo_data
error_exit
su - chorus -c "ln -sfn %{shared}/demo_data %{releases}/demo_data"
error_exit
log "Linking data folders to %{shared}"
rm -rf %{shared}/db
error_exit
rm -rf %{shared}/log
error_exit
rm -rf %{shared}/solr/data
error_exit
rm -rf %{shared}/system
error_exit
su - chorus -c "chmod 700 %{data}/db"
error_exit
su - chorus -c "ln -sfn %{data}/db %{shared}/db"
error_exit
su - chorus -c "ln -sfn %{data}/log %{shared}/log"
error_exit
su - chorus -c "ln -sfn %{data}/solr/data %{shared}/solr/data"
error_exit
su - chorus -c "ln -sfn %{data}/system %{shared}/system"
error_exit
log "Linking shared data folders to %{releases}"
rm -rf %{releases}/log
rm -rf %{releases}/postgres-db
rm -rf %{releases}/solr/data
rm -rf %{releases}/tmp
su - chorus -c "ln -sfn %{shared}/log %{releases}/log"
error_exit
su - chorus -c "ln -sfn %{shared}/db %{releases}/postgres-db"
error_exit
su - chorus -c "ln -sfn %{shared}/solr/data %{releases}/solr/data"
error_exit
su - chorus -c "ln -sfn %{shared}/tmp %{releases}/tmp"
error_exit
log "Linking nginx logs to %{releases}/vendor/nginx/nginx_dist/nginx_data/logs"
su - chorus -c "mkdir -p %{shared}/log/nginx"
error_exit
rm -rf %{releases}/vendor/nginx/nginx_dist/nginx_data/logs
error_exit
su - chorus -c "ln -sfn %{shared}/log/nginx %{releases}/vendor/nginx/nginx_dist/nginx_data/logs"
error_exit
rm -rf %{releases}/system
error_exit
su - chorus -c "ln -sfn %{shared}/system %{releases}/system"
error_exit
log "Linking version_build to %{appdir}/version_build"
su - chorus -c "ln -sf %{releases}/version_build %{appdir}/version_build"
error_exit
log "Linking chorus_control.sh and chorus_server to %{appdir}"
su - chorus -c "ln -sf %{releases}/packaging/chorus_control.sh %{appdir}/chorus_control.sh"
error_exit
su - chorus -c "ln -sf %{releases}/packaging/setup/chorus_server %{appdir}/chorus_server"
error_exit
log "Generating chorus_path.sh to %{appdir}"
su - chorus -c "echo 'export CHORUS_HOME=%{prefix}/%{name}' > %{appdir}/chorus_path.sh"
error_exit
su - chorus -c "echo 'export PATH=\$PATH:\$CHORUS_HOME' >> %{appdir}/chorus_path.sh"
error_exit
su - chorus -c "echo 'export PGPASSFILE=\$CHORUS_HOME/.pgpass' >> %{appdir}/chorus_path.sh"
error_exit
log "source chorus_path.sh in ~/.bash_profile.sh"
su - chorus -c "echo 'source %{appdir}/chorus_path.sh' >> ~/.bash_profile"
error_exit
su - chorus -c "chmod -R 0555 %{releases}/public"
error_exit
log "extract postgres database"

if [[ (-f /etc/redhat-release) && (`uname -a | grep x86_64` != "") ]]; then
    OS_VERSION="RedHat"
    VERSION_ID=`cat /etc/redhat-release |awk '{print $3}'|cut -d'.' -f1-1`
elif [[ (-f /etc/SuSE-release) && (`cat /etc/SuSE-release | grep x86_64` != "") ]]; then
    OS_VERSION="SuSE"
    VERSION_ID=`cat /etc/SuSE-release|grep SUSE|awk '{print $5}'`
fi
if [[ ${OS_VERSION} == "RedHat" && ${VERSION_ID} == "5" ]]; then
	su - chorus -c "tar -xzf %{releases}/packaging/postgres/postgres-redhat5.5-9.2.4.tar.gz -C %{releases}"
	error_exit
	log "postgres-redhat5.5-9.2.4 extracted in %{releases}/postgres"
elif [[ ${OS_VERSION} == "RedHat" && ${VERSION_ID} == "6" ]]; then
	su - chorus -c "tar -xzf %{releases}/packaging/postgres/postgres-redhat6.2-9.2.4.tar.gz -C %{releases}"
	error_exit
	log "postgres-redhat6.2-9.2.4 extracted in %{releases}/postgres"
elif [[ ${OS_VERSION} == "SuSE" && ${VERSION_ID} == "11" ]]; then
	su - chorus -c	"tar -xzf %{releases}/packaging/postgres/postgres-suse11-9.2.4.tar.gz -C %{releases}"
	error_exit
	log "postgres-suse11-9.2.4 extracted in %{releases}/postgres"
else
	log "postgres not installed, no version match the operation system"
fi
log "Linking current release to %{appdir}/current"
rm -rf %{appdir}/current
error_exit
su - chorus -c "ln -sfn %{releases} %{appdir}/current"
error_exit
echo " 
*********************************************************
* successfully install chorus in %{appdir}:	*
* data dir is in %{data}				*
* please change to chorus user(running su - chorus)	* 
* and running chorus_server setup to setup chorus	*
*********************************************************"
%files
%defattr(-,chorus,chorus,-)
%doc
%config(noreplace) %{data}
%{appdir}
%changelog

