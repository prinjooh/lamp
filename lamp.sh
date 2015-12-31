#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#==============================================================================================#
#   System Required:  CentOS / RedHat / Fedora                                                 #
#   Description:  Install LAMP(Linux + Apache + MySQL + PHP ) for CentOS / RedHat / Fedora     #
#   Author: Teddysun <i@teddysun.com>                                                          #
#   Intro:  https://lamp.sh                                                                    #
#==============================================================================================#

# Install time state
StartDate=''
StartDateSecond=''
# PHP disable fileinfo
PHPDisable=''
# Software Version
MySQLVersion1='mysql-5.5.47'
MySQLVersion2='mysql-5.6.28'
MySQLVersion3='mysql-5.7.10'
MariaDBVersion1='mariadb-5.5.47'
MariaDBVersion2='mariadb-10.0.23'
MariaDBVersion3='mariadb-10.1.10'
PHPVersion1='php-5.4.45'
PHPVersion2='php-5.3.29'
PHPVersion3='php-5.5.30'
PHPVersion4='php-5.6.16'
PHPVersion5='php-7.0.1'
ApacheVersion='httpd-2.4.18'
phpMyAdminVersion='phpMyAdmin-4.4.15.2-all-languages'
aprVersion='apr-1.5.2'
aprutilVersion='apr-util-1.5.4'
libiconvVersion='libiconv-1.14'
libmcryptVersion='libmcrypt-2.5.8'
mhashVersion='mhash-0.9.9.9'
mcryptVersion='mcrypt-2.6.8'
re2cVersion='re2c-0.13.6'
pcreVersion='pcre-8.37'
libeditVersion='libedit-20150325-3.1'
imapVersion='imap-2007f'
# Current folder
cur_dir=`pwd`
# CPU Number
Cpunum=`cat /proc/cpuinfo | grep 'processor' | wc -l`;

# Get public IP
function getIP(){
    IP=`ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\." | head -n 1`
    if [[ "$IP" = "" ]]; then
        IP=`wget -qO- -t1 -T2 ipv4.icanhazip.com`
    fi
}

# is 64bit or not
function is_64bit(){
    if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
        return 0
    else
        return 1
    fi        
}

# Get version
function getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else    
        grep -oE  "[0-9.]+" /etc/issue
    fi    
}

# CentOS version
function centosversion(){
    local code=$1
    local version="`getversion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi        
}

# Make sure only root can run our script
function rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

# Check system infomation
function check_sys(){
    cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
    freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    tram=$( free -m | awk '/Mem/ {print $2}' )
    swap=$( free -m | awk '/Swap/ {print $2}' )
    up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60;d=$1%60} {printf("%ddays, %d:%d:%d\n",a,b,c,d)}' /proc/uptime )
    opsy=$( awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release )
    arch=$( uname -m )
    lbit=$( getconf LONG_BIT )
    host=$( hostname )
    kern=$( uname -r )
    RamSum=`expr $tram + $swap`
    if [ $RamSum -lt 480 ]; then
        echo "Error: Not enough memory to install LAMP. The system needs memory: ${tram}MB*RAM + ${swap}MB*Swap > 480MB"
        exit 1
    fi
    [ $RamSum -lt 600 ] && PHPDisable='--disable-fileinfo';
}

# Disable selinux
function disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

# Pre-installation settings
function pre_installation_settings(){
    clear
    echo ""
    echo "#############################################################"
    echo "# LAMP Auto Install Script for CentOS / RedHat / Fedora     #"
    echo "# Intro: https://lamp.sh                                    #"
    echo "# Author: Teddysun <i@teddysun.com>                         #"
    echo "#############################################################"
    echo ""
    # Display System information
    getIP
    echo "System information is below"
    echo ""
    echo "CPU model            : $cname"
    echo "Number of cores      : $cores"
    echo "CPU frequency        : $freq MHz"
    echo "Total amount of ram  : $tram MB"
    echo "Total amount of swap : $swap MB"
    echo "System uptime        : $up"
    echo "OS                   : $opsy"
    echo "Arch                 : $arch ($lbit Bit)"
    echo "Kernel               : $kern"
    echo "IPv4 address         : $IP"
    echo ""
    # Choose databese
    while true
    do
    echo "Please choose a version of the Database:"
    echo -e "\t\033[32m1\033[0m. Install $MySQLVersion1"
    echo -e "\t\033[32m2\033[0m. Install $MySQLVersion2(recommend)"
    echo -e "\t\033[32m3\033[0m. Install $MySQLVersion3"
    echo -e "\t\033[32m4\033[0m. Install $MariaDBVersion1"
    echo -e "\t\033[32m5\033[0m. Install $MariaDBVersion2"
    echo -e "\t\033[32m6\033[0m. Install $MariaDBVersion3"
    read -p "Please input a number:(Default 2) " DB_version
    [ -z "$DB_version" ] && DB_version=2
    case $DB_version in
        1|2|3|4|5|6)
        echo ""
        echo "---------------------------"
        echo "You choose = $DB_version"
        echo "---------------------------"
        echo ""
        break
        ;;
        *)
        echo "Input error! Please only input number 1-6"
    esac
    done
    # Set MySQL or MariaDB root password
    echo "Please input the root password of MySQL or MariaDB:"
    read -p "(Default password: root):" dbrootpwd
    [ -z "$dbrootpwd" ] && dbrootpwd="root"
    echo ""
    echo "---------------------------"
    echo "Password = $dbrootpwd"
    echo "---------------------------"
    echo ""
    # Choose PHP version
    while true
    do
    echo "Please choose a version of the PHP:"
    echo -e "\t\033[32m1\033[0m. Install $PHPVersion1"
    echo -e "\t\033[32m2\033[0m. Install $PHPVersion2"
    echo -e "\t\033[32m3\033[0m. Install $PHPVersion3(recommend)"
    echo -e "\t\033[32m4\033[0m. Install $PHPVersion4"
    echo -e "\t\033[32m5\033[0m. Install $PHPVersion5"
    read -p "Please input a number:(Default 3) " PHP_version
    [ -z "$PHP_version" ] && PHP_version=3
    case $PHP_version in
        1|2|3|4|5)
        echo ""
        echo "---------------------------"
        echo "You choose = $PHP_version"
        echo "---------------------------"
        echo ""
        break
        ;;
        *)
        echo "Input error! Please only input number 1-5"
    esac
    done

    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo ""
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`

    #Remove Packages
    cd ~
    yum -y remove httpd*
    yum -y remove mysql*
    yum -y remove php*
    #Set timezone
    rm -f /etc/localtime
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    yum -y install ntp
    ntpdate -d cn.pool.ntp.org
    StartDate=$(date);
    StartDateSecond=$(date +%s);
    echo "Start time: ${StartDate}";
    #Install necessary tools
    if [ ! -s /etc/yum.conf.bak ]; then
        cp /etc/yum.conf /etc/yum.conf.bak
    fi
    sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf
    packages="wget autoconf automake bison bzip2 bzip2-devel curl curl-devel cmake cpp crontabs diffutils tar e2fsprogs-devel expat-devel file flex freetype-devel gcc gcc-c++ gd glibc-devel glib2-devel gettext-devel gmp-devel icu kernel-devel libaio libtool-libs libjpeg-devel libpng-devel libxslt libxslt-devel libxml2 libxml2-devel libidn-devel libcap-devel libtool-ltdl-devel libc-client-devel libicu libicu-devel lynx zip zlib-devel unzip patch mlocate make ncurses-devel readline readline-devel vim-minimal sendmail pam-devel pcre pcre-devel openldap openldap-devel openssl openssl-devel"
    for package in $packages;
    do yum -y install $package; done
}

# Download all files
function download_all_files(){
    cd $cur_dir
    if   [ $PHP_version -eq 1 ]; then
        download_file "${PHPVersion1}.tar.gz"
    elif [ $PHP_version -eq 2 ]; then
        download_file "${PHPVersion2}.tar.gz"
        download_file "php5.3.patch"
    elif [ $PHP_version -eq 3 ]; then
        download_file "${PHPVersion3}.tar.gz"
    elif [ $PHP_version -eq 4 ]; then
        download_file "${PHPVersion4}.tar.gz"
    elif [ $PHP_version -eq 5 ]; then
        download_file "${PHPVersion5}.tar.gz"
    fi
    download_file "${ApacheVersion}.tar.gz"
    download_file "${phpMyAdminVersion}.tar.gz"
    download_file "${aprVersion}.tar.gz"
    download_file "${aprutilVersion}.tar.gz"
    download_file "${libiconvVersion}.tar.gz"
    download_file "${libmcryptVersion}.tar.gz"
    download_file "${mhashVersion}.tar.gz"
    download_file "${mcryptVersion}.tar.gz"
    download_file "${re2cVersion}.tar.gz"
    download_file "${pcreVersion}.tar.gz"
    download_file "${libeditVersion}.tar.gz"
    if centosversion 7; then
        download_file "${imapVersion}.tar.gz"
    fi
}

# Download file
function download_file(){
    if [ -s $1 ]; then
        echo "$1 [found]"
    else
        echo "$1 not found!!!download now......"
        if ! wget -c http://lamp.teddysun.com/files/$1;then
            echo "Failed to download $1, please download it to "$cur_dir" directory manually and try again."
            exit 1
        fi
    fi
}

# Untar all files
function untar_all_files(){
    echo "Untar all files, please wait a moment..."
    if [ -d $cur_dir/untar ]; then
        rm -rf $cur_dir/untar
    fi
    mkdir -p $cur_dir/untar
    for file in `ls *.tar.gz`;
    do
        tar -zxf $file -C $cur_dir/untar
    done
    echo "Untar all files completed!"
}

# Install Apache
function install_apache(){
    if [ ! -d /usr/local/apache/bin ];then
        #Install Apache
        echo "Start Installing ${ApacheVersion}"
        mv $cur_dir/untar/$aprVersion $cur_dir/untar/$ApacheVersion/srclib/apr
        mv $cur_dir/untar/$aprutilVersion $cur_dir/untar/$ApacheVersion/srclib/apr-util
        cd $cur_dir/untar/$ApacheVersion
        ./configure \
        --prefix=/usr/local/apache \
        --with-pcre=/usr/local/pcre \
        --with-mpm=prefork \
        --with-included-apr \
        --enable-so \
        --enable-dav \
        --enable-deflate=shared \
        --enable-ssl=shared \
        --enable-expires=shared  \
        --enable-headers=shared \
        --enable-rewrite=shared \
        --enable-static-support \
        --enable-modules=all \
        --enable-mods-shared=all
        make -j $Cpunum
        make install
        if [ $? -ne 0 ]; then
            echo "Installing Apache failed, Please visit https://lamp.sh/support.html and contact."
            exit 1
        fi
        if centosversion 7; then
            cp -f /usr/local/apache/bin/apachectl /etc/init.d/httpd
            sed -i '2a # chkconfig: - 85 15' /etc/init.d/httpd
            sed -i '3a # description: Apache is a World Wide Web server. It is used to server' /etc/init.d/httpd
        else
            cp -f $cur_dir/conf/httpd.init /etc/init.d/httpd
        fi
        chmod +x /etc/init.d/httpd
        chkconfig --add httpd
        chkconfig httpd on
        rm -rf /etc/httpd
        ln -s /usr/local/apache/ /etc/httpd
        cd /usr/sbin/
        ln -fs /usr/local/apache/bin/httpd
        ln -fs /usr/local/apache/bin/apachectl
        cd /var/log
        rm -rf httpd/
        ln -s /usr/local/apache/logs httpd
        id -u apache >/dev/null 2>&1
        [ $? -ne 0 ] && useradd -M -U -s /sbin/nologin apache
        mkdir -p /data/www/default/
        chmod -R 755 /data/www/default/
        mkdir -p /usr/local/apache/conf/vhost/
        touch /usr/local/apache/conf/vhost/none.conf
        #Copy to config files
        cp -f $cur_dir/conf/httpd2.4.conf /usr/local/apache/conf/httpd.conf
        cp -f $cur_dir/conf/{httpd-vhosts.conf,httpd-info.conf,httpd-default.conf} /usr/local/apache/conf/extra/
        cp -f $cur_dir/conf/{index.html,lamp.gif,p.php,jquery.js,phpinfo.php} /data/www/default/
        echo "${ApacheVersion} Install completed!"
    else
        echo "Apache had been installed!"
    fi
}

# Install database
function install_database(){
    if [ -d "/proc/vz" ]; then
        [ -z "`grep 'ulimit' /etc/profile`" ] && echo "ulimit -s unlimited" >> /etc/profile
        . /etc/profile
    fi
    if [ $DB_version -le 3 ]; then
        install_mysql
    else
        install_mariadb
    fi
}

# Install mariadb database
function install_mariadb(){
    # Install MariaDB repo
    if [ ! -f /etc/yum.repos.d/mariadb.repo ]; then
        if [[ -s /etc/redhat-release ]]; then
            [[ ! -z "`egrep -i 'CentOS' /etc/redhat-release`" ]] && maria_os='centos'
            [[ ! -z "`egrep -i 'Fedora' /etc/redhat-release`" ]] && maria_os='fedora'
            [[ ! -z "`egrep -i 'Red Hat' /etc/redhat-release`" ]] && maria_os='rhel'
            version=$(grep -oE  "[0-9.]+" /etc/redhat-release)
            maria_os_ver=${version%%.*}
            if   [ $DB_version -eq 4 ]; then
                maria_ver='5.5'
            elif [ $DB_version -eq 5 ]; then
                maria_ver='10.0'
            elif [ $DB_version -eq 6 ]; then
                maria_ver='10.1'
            fi
            if  [ "$lbit" == "64" ]; then
                maria_bit='amd64'
            else
                maria_bit='x86'
            fi
            echo "[mariadb]" >> /etc/yum.repos.d/mariadb.repo
            echo "name = MariaDB" >> /etc/yum.repos.d/mariadb.repo
            echo "baseurl = http://yum.mariadb.org/${maria_ver}/${maria_os}${maria_os_ver}-${maria_bit}" >> /etc/yum.repos.d/mariadb.repo
            echo "gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB" >> /etc/yum.repos.d/mariadb.repo
            echo "gpgcheck=1" >> /etc/yum.repos.d/mariadb.repo
        else
            echo "File /etc/redhat-release is not exist, please check it and retry."
            exit 1
        fi
    else
        echo "MariaDB repo already exist."
    fi
    # Yum install MariaDB
    yum install -y MariaDB-server MariaDB-client
    chmod +x /etc/init.d/mysql
    chkconfig --add mysql
    chkconfig mysql on
    # Start MariaDB service
    /etc/init.d/mysql start
    mysqladmin password $dbrootpwd
    mysql -uroot -p$dbrootpwd <<EOF
drop database if exists test;
delete from mysql.user where user='';
update mysql.user set password=password('$dbrootpwd') where user='root';
delete from mysql.user where not (user='root') ;
flush privileges;
exit
EOF
    # Stop MariaDB service
    /etc/init.d/mysql stop
    echo "MariaDB Install completed!"
}

# Install mysql database
function install_mysql(){
    # Install mysql community repo
    if [ ! -f /etc/yum.repos.d/mysql-community.repo ]; then
        if [[ -s /etc/redhat-release ]]; then
            [[ ! -z "`egrep -i 'CentOS' /etc/redhat-release`" ]] && mysql_os='el'
            [[ ! -z "`egrep -i 'Fedora' /etc/redhat-release`" ]] && mysql_os='fc'
            [[ ! -z "`egrep -i 'Red Hat' /etc/redhat-release`" ]] && mysql_os='el'
            version=$(grep -oE  "[0-9.]+" /etc/redhat-release)
            mysql_os_ver=${version%%.*}
            if   [ $DB_version -eq 1 ]; then
                mysql_ver='5.5'
            elif [ $DB_version -eq 2 ]; then
                mysql_ver='5.6'
            elif [ $DB_version -eq 3 ]; then
                mysql_ver='5.7'
            fi
            echo "[mysql-community]" >> /etc/yum.repos.d/mysql-community.repo
            echo "name=MySQL ${mysql_ver} Community Server" >> /etc/yum.repos.d/mysql-community.repo
            echo "baseurl=http://repo.mysql.com/yum/mysql-${mysql_ver}-community/${mysql_os}/${mysql_os_ver}/\$basearch/" >> /etc/yum.repos.d/mysql-community.repo
            echo "enabled=1" >> /etc/yum.repos.d/mysql-community.repo
            echo "gpgcheck=0" >> /etc/yum.repos.d/mysql-community.repo
        else
            echo "File /etc/redhat-release is not exist, please check it and retry."
            exit 1
        fi
    else
        echo "mysql community repo already exist."
    fi
    yum install -y mysql-community-server
    chmod +x /etc/init.d/mysqld
    chkconfig --add mysqld
    chkconfig mysqld on
    # Start mysql community service
    /etc/init.d/mysqld start
    if [ $DB_version -eq 3 ]; then
        # Display temporary password
        dbrootpwd=$(grep 'temporary password' /var/log/mysqld.log | awk -F: '{print $4}' | sed 's/^[ \t]*//;s/[ \t]*$//')
        echo "For MySQL 5.7 only: A temporary password is generated for root@localhost"
        echo "For MySQL 5.7 only: A temporary password is:${dbrootpwd}"
    else
        mysqladmin password $dbrootpwd
    fi
    mysql -uroot -p$dbrootpwd <<EOF
drop database if exists test;
delete from mysql.user where user='';
update mysql.user set password=password('$dbrootpwd') where user='root';
delete from mysql.user where not (user='root') ;
flush privileges;
exit
EOF
    # Stop mysql community service
    /etc/init.d/mysqld stop
    echo "MySQL Install completed!"
}

#Install pcre dependency
function install_pcre(){
    if [ ! -d /usr/local/pcre ]; then
        cd $cur_dir/untar/$pcreVersion
        ./configure --prefix=/usr/local/pcre
        make && make install
        if is_64bit; then
            ln -s /usr/local/pcre/lib /usr/local/pcre/lib64
        fi
        [ -d "/usr/local/pcre/lib" ] && export LD_LIBRARY_PATH=/usr/local/pcre/lib:$LD_LIBRARY_PATH
        [ -d "/usr/local/pcre/bin" ] && export PATH=/usr/local/pcre/bin:$PATH
        echo "${pcreVersion} install completed!"
    else
        echo "pcre had been installed!"
    fi
}

# Install libiconv dependency
function install_libiconv(){
    if [ ! -d /usr/local/libiconv ]; then
        cd $cur_dir/untar/$libiconvVersion
        ./configure --prefix=/usr/local/libiconv
        make && make install
        echo "${libiconvVersion} install completed!"
    else
        echo "libiconv had been installed!"
    fi
}

# Install libmcrypt dependency
function install_libmcrypt(){
    cd $cur_dir/untar/$libmcryptVersion
    ./configure
    make && make install
    echo "${libmcryptVersion} install completed!"
}

# Install mhash dependency
function install_mhash(){
    cd $cur_dir/untar/$mhashVersion
    ./configure
    make && make install
    echo "${mhashVersion} install completed!"
}

# Install libmcrypt dependency
function install_mcrypt(){
    /sbin/ldconfig
    cd $cur_dir/untar/$mcryptVersion
    ./configure
    make && make install
    echo "${mcryptVersion} install completed!"
}

# Install re2c dependency
function install_re2c(){
    cd $cur_dir/untar/$re2cVersion
    ./configure
    make && make install
    echo "${re2cVersion} install completed!"
}

# Install libedit dependency
function install_libedit(){
    cd $cur_dir/untar/$libeditVersion
    ./configure --enable-widec
    make && make install
    echo "${libeditVersion} install completed!"
}

# Install imap dependency
function install_imap(){
    if centosversion 7; then
        cd $cur_dir/untar/$imapVersion
        if is_64bit; then
            make lr5 PASSWDTYPE=std SSLTYPE=unix.nopwd EXTRACFLAGS=-fPIC IP=4
        else
            make lr5 PASSWDTYPE=std SSLTYPE=unix.nopwd IP=4
        fi
        rm -rf /usr/local/imap-2007f/
        mkdir /usr/local/imap-2007f/
        mkdir /usr/local/imap-2007f/include/
        mkdir /usr/local/imap-2007f/lib/
        cp c-client/*.h /usr/local/imap-2007f/include/
        cp c-client/*.c /usr/local/imap-2007f/lib/
        cp c-client/c-client.a /usr/local/imap-2007f/lib/libc-client.a
        echo "${imapVersion} install completed!"
    fi
}

# Update ICU version
function update_icu(){
    echo "Update ICU version start..."
    cd $cur_dir
    if ! wget -c http://lamp.teddysun.com/files/icu4c-4_4_2-src.tgz; then
        echo "Failed to download icu4c-4_4_2-src.tgz, please download it to "$cur_dir" directory manually and try again."
        exit 1
    fi
    tar zxf icu4c-4_4_2-src.tgz -C $cur_dir/untar
    cd $cur_dir/untar/icu/source/
    ./configure
    make && make install
    rm -f $cur_dir/icu4c-4_4_2-src.tgz
    echo "ICU version update completed!"
}

# Update gmp version
function update_gmp(){
    echo "Update gmp version start..."
    cd $cur_dir
    if ! wget -c http://lamp.teddysun.com/files/gmp-6.1.0.tar.bz2; then
        echo "Failed to download gmp-6.1.0.tar.bz2, please download it to "$cur_dir" directory manually and try again."
        exit 1
    fi
    tar jxf gmp-6.1.0.tar.bz2 -C $cur_dir/untar
    cd $cur_dir/untar/gmp-6.1.0/
    ./configure
    make && make install
    rm -f $cur_dir/gmp-6.1.0.tar.bz2
    echo "gmp version update completed!"
}

# Install PHP5
function install_php(){
    if [ ! -d /usr/local/php ];then
        echo "Start Installing PHP"
        # database compile dependency
        if [ $PHP_version -eq 5 ]; then
            WITH_MYSQL=""
            WITH_MYSQLI="--with-mysqli=mysqlnd"
        else
            WITH_MYSQL="--with-mysql=mysqlnd"
            WITH_MYSQLI="--with-mysqli=mysqlnd"
        fi
        # ldap module dependency 
        if is_64bit; then
            cp -rpf /usr/lib64/libldap* /usr/lib/
            cp -rpf /usr/lib64/liblber* /usr/lib/
        fi
        # imap module dependency
        if [ -f /usr/lib64/libc-client.so ];then
            ln -s /usr/lib64/libc-client.so /usr/lib/libc-client.so
        fi
        if centosversion 7; then
            WITH_IMAP="--with-imap=/usr/local/imap-2007f --with-imap-ssl"
        else
            WITH_IMAP="--with-imap --with-imap-ssl --with-kerberos"
        fi
        # update ICU & gmp version
        WITH_GMP="--with-gmp"
        WITH_ICU_DIR="--with-icu-dir=/usr"
        if centosversion 5; then
            if [[ "$PHP_version" = "3" || "$PHP_version" = "4" || "$PHP_version" = "5" ]];then
                update_icu
                update_gmp
                WITH_GMP="--with-gmp=/usr/local"
                WITH_ICU_DIR="--with-icu-dir=/usr/local"
            fi
        fi
        if   [ $PHP_version -eq 1 ]; then
            cd $cur_dir/untar/$PHPVersion1
        elif [ $PHP_version -eq 2 ]; then
            cd $cur_dir/untar/$PHPVersion2
            # Add PHP5.3 patch
            patch -p1 < $cur_dir/php5.3.patch
        elif [ $PHP_version -eq 3 ]; then
            cd $cur_dir/untar/$PHPVersion3
        elif [ $PHP_version -eq 4 ]; then
            cd $cur_dir/untar/$PHPVersion4
        elif [ $PHP_version -eq 5 ]; then
            cd $cur_dir/untar/$PHPVersion5
        fi
        ./configure \
        --prefix=/usr/local/php \
        --with-apxs2=/usr/local/apache/bin/apxs \
        --with-config-file-path=/usr/local/php/etc \
        $WITH_MYSQL \
        $WITH_MYSQLI \
        --with-pcre-dir=/usr/local/pcre \
        --with-iconv-dir=/usr/local/libiconv \
        --with-mysql-sock=/var/lib/mysql/mysql.sock \
        --with-config-file-scan-dir=/usr/local/php/php.d \
        --with-mhash=/usr \
        $WITH_ICU_DIR \
        --with-bz2 \
        --with-curl \
        --with-freetype-dir \
        --with-gd \
        --with-gettext \
        $WITH_GMP \
        --with-jpeg-dir \
        $WITH_IMAP \
        --with-ldap \
        --with-ldap-sasl \
        --with-mcrypt \
        --with-openssl \
        --without-pear \
        --with-pdo-mysql \
        --with-png-dir \
        --with-readline \
        --with-xmlrpc \
        --with-xsl \
        --with-zlib \
        --enable-bcmath \
        --enable-calendar \
        --enable-ctype \
        --enable-dom \
        --enable-exif \
        --enable-ftp \
        --enable-gd-native-ttf \
        --enable-intl \
        --enable-json \
        --enable-mbstring \
        --enable-pcntl \
        --enable-session \
        --enable-shmop \
        --enable-simplexml \
        --enable-soap \
        --enable-sockets \
        --enable-tokenizer \
        --enable-wddx \
        --enable-xml \
        --enable-zip $PHPDisable
        if [ $? -ne 0 ]; then
            echo "PHP configure failed, Please visit https://lamp.sh/support.html and contact."
            exit 1
        fi
        make -j $Cpunum
        make install
        if [ $? -ne 0 ]; then
            echo "Installing PHP failed, Please visit https://lamp.sh/support.html and contact."
            exit 1
        fi
        mkdir -p /usr/local/php/etc
        mkdir -p /usr/local/php/php.d
        if   [ $PHP_version -eq 1 ]; then
            mkdir -p /usr/local/php/lib/php/extensions/no-debug-non-zts-20100525
        elif [ $PHP_version -eq 2 ]; then
            mkdir -p /usr/local/php/lib/php/extensions/no-debug-non-zts-20090626
        elif [ $PHP_version -eq 3 ]; then
            mkdir -p /usr/local/php/lib/php/extensions/no-debug-non-zts-20121212
        elif [ $PHP_version -eq 4 ]; then
            mkdir -p /usr/local/php/lib/php/extensions/no-debug-non-zts-20131226
        elif [ $PHP_version -eq 5 ]; then
            mkdir -p /usr/local/php/lib/php/extensions/no-debug-non-zts-20151012
        fi
        cp -f $cur_dir/conf/php.ini /usr/local/php/etc/php.ini
        rm -f /etc/php.ini
        ln -s /usr/local/php/etc/php.ini /etc/php.ini
        ln -s /usr/local/php/bin/php /usr/bin/php
        ln -s /usr/local/php/bin/php-config /usr/bin/php-config
        ln -s /usr/local/php/bin/phpize /usr/bin/phpize
        echo "PHP install completed!"
    else
        echo "PHP had been installed!"
    fi
}

# Install phpmyadmin
function install_phpmyadmin(){
    if [ -d /data/www/default/phpmyadmin ];then
        rm -rf /data/www/default/phpmyadmin
    fi
    echo "Start Installing ${phpMyAdminVersion}"
    cd $cur_dir
    mv untar/$phpMyAdminVersion /data/www/default/phpmyadmin
    cp -f $cur_dir/conf/config.inc.php /data/www/default/phpmyadmin/config.inc.php
    # Start mysql service
    if [ $DB_version -le 3 ]; then
        /etc/init.d/mysqld start
    else
        /etc/init.d/mysql start
    fi
    # Create phpmyadmin database
    mysql -uroot -p$dbrootpwd < /data/www/default/phpmyadmin/sql/create_tables.sql
    mysql -uroot -p$dbrootpwd -e "INSERT INTO \`phpmyadmin\`.\`pma__userconfig\` VALUES ('root',now(),'{\"VersionCheck\":false,\"collation_connection\":\"utf8mb4_unicode_ci\"}');"
    chmod -R 755 /data/www/default/phpmyadmin
    mkdir -p /data/www/default/phpmyadmin/upload/
    mkdir -p /data/www/default/phpmyadmin/save/
    chown -R apache:apache /data/www/default
    echo "${phpMyAdminVersion} Install completed!"
}

# Install end cleanup
function install_cleanup(){
    # Start httpd service
    /etc/init.d/httpd start
    cp -f $cur_dir/lamp.sh /usr/bin/lamp
    cp -f $cur_dir/conf/httpd.logrotate /etc/logrotate.d/httpd
    # Clean up
    cd $cur_dir
    echo "Clean up start..."
    for dfile in `ls *.tar.gz`;
    do
        rm -f $dfile
        echo "Delete $dfile success."
    done
    rm -rf $cur_dir/untar
    echo "Clean up complete..."

    clear
    # Install completed or not 
    if [ -s /usr/local/apache ] && [ -s /usr/local/php ] && [ -s /var/lib/mysql ]; then
        echo ""
        echo 'Congratulations, LAMP install completed!'
        echo "Your Default Website: http://${IP}"
        echo 'Default WebSite Root Dir: /data/www/default'
        echo 'Apache Dir: /usr/local/apache'
        echo 'PHP Dir: /usr/local/php'
        if [ $DB_version -le 3 ]; then
            echo "MySQL root password:$dbrootpwd"
        else
            echo "MariaDB root password:$dbrootpwd"
        fi
        echo -e "Installed Apache version:\033[41;37m ${ApacheVersion} \033[0m"
        if   [ $DB_version -eq 1 ]; then
            echo -e "Installed MySQL version:\033[41;37m ${MySQLVersion1} \033[0m"
        elif [ $DB_version -eq 2 ]; then
            echo -e "Installed MySQL version:\033[41;37m ${MySQLVersion2} \033[0m"
        elif [ $DB_version -eq 3 ]; then
            echo -e "Installed MySQL version:\033[41;37m ${MySQLVersion3} \033[0m"
        elif [ $DB_version -eq 4 ]; then
            echo -e "Installed MariaDB version:\033[41;37m ${MariaDBVersion1} \033[0m"
        elif [ $DB_version -eq 5 ]; then
            echo -e "Installed MariaDB version:\033[41;37m ${MariaDBVersion2} \033[0m"
        elif [ $DB_version -eq 6 ]; then
            echo -e "Installed MariaDB version:\033[41;37m ${MariaDBVersion3} \033[0m"
        fi
        if   [ $PHP_version -eq 1 ]; then
            echo -e "Installed PHP version:\033[41;37m ${PHPVersion1} \033[0m"
        elif [ $PHP_version -eq 2 ]; then
            echo -e "Installed PHP version:\033[41;37m ${PHPVersion2} \033[0m"
        elif [ $PHP_version -eq 3 ]; then
            echo -e "Installed PHP version:\033[41;37m ${PHPVersion3} \033[0m"
        elif [ $PHP_version -eq 4 ]; then
            echo -e "Installed PHP version:\033[41;37m ${PHPVersion4} \033[0m"
        elif [ $PHP_version -eq 5 ]; then
            echo -e "Installed PHP version:\033[41;37m ${PHPVersion5} \033[0m"
        fi
        echo -e "Installed phpMyAdmin version:\033[41;37m ${phpMyAdminVersion} \033[0m"
        echo ""
        echo "Start time: ${StartDate}"
        echo -e "Completion time: $(date) (Use:\033[41;37m $[($(date +%s)-StartDateSecond)/60] \033[0m minutes)"
        echo "Welcome to visit https://lamp.sh"
        echo "Enjoy it!"
        echo ""
    else
        echo ""
        echo "Sorry, Failed to install LAMP!"
        echo "Please visit https://lamp.sh/support.html and contact."
    fi
}

# Uninstall lamp
function uninstall_lamp(){
    echo "Are you sure uninstall LAMP? (y/n)"
    read -p "(Default: n):" uninstall
    if [ -z $uninstall ]; then
        uninstall="n"
    fi
    if [[ "$uninstall" = "y" || "$uninstall" = "Y" ]]; then
        clear
        echo "==========================="
        echo "Yes, I agreed to uninstall!"
        echo "==========================="
        echo ""
    else
        echo ""
        echo "============================"
        echo "You cancelled the uninstall!"
        echo "============================"
        exit
    fi

    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo "Press any key to start uninstall LAMP...or Press Ctrl+c to cancel"
    echo ""
    char=`get_char`

    if [[ "$uninstall" = "y" || "$uninstall" = "Y" ]]; then
        /etc/init.d/httpd stop
        chkconfig --del httpd
        [ -e /etc/init.d/mysqld ] && /etc/init.d/mysqld stop && chkconfig --del mysqld && yum remove -y mysql-community-*
        [ -e /etc/init.d/mysql ] && /etc/init.d/mysql stop && chkconfig --del mysql && yum remove -y MariaDB-*
        rm -rf /etc/init.d/httpd /usr/local/apache /usr/sbin/httpd /usr/sbin/apachectl /var/log/httpd /var/lock/subsys/httpd /var/spool/mail/apache /etc/logrotate.d/httpd
        rm -rf /var/lib/mysql /var/lib64/mysql/ /etc/my.cnf 
        rm -rf /usr/local/php /usr/lib/php /usr/bin/php /usr/bin/php-config /usr/bin/phpize /etc/php.ini
        rm -rf /data/www/default/phpmyadmin
        rm -rf /data/www/default/xcache
        rm -f /etc/pure-ftpd.conf
        rm -f /usr/bin/lamp
        echo "Successfully uninstall LAMP!!"
    else
        echo "Uninstall cancelled, nothing to do"
    fi
}

# Add apache virtualhost
function vhost_add(){
    # Define domain name
    read -p "Please input domains such as:www.example.com:" domains
    if [ -z "$domains" ]; then
        echo "You need input a domain."
        exit 1
    fi
    domain=`echo $domains | awk '{print $1}'`
    if [ -f "/usr/local/apache/conf/vhost/$domain.conf" ]; then
        echo "$domain is exist!"
        exit 1
    fi
    # Create database or not    
    while true
    do
    read -p "Do you want to create database?[y/n]:" create
    case $create in
    y|Y|YES|yes|Yes)
    if [ -d /usr/local/mysql ]; then
        read -p "Please input your MySQL root password:" mysqlroot_passwd
        mysql -uroot -p$mysqlroot_passwd <<EOF
exit
EOF
        if [ $? -eq 0 ]; then
            echo "MySQL root password is correct.";
        else
            echo "MySQL root password incorrect! Please check it and try again!"
            exit 1
        fi
    elif [ -d /usr/local/mariadb ]; then
        read -p "Please input your MariaDB root password:" mysqlroot_passwd
        mysql -uroot -p$mysqlroot_passwd <<EOF
exit
EOF
        if [ $? -eq 0 ]; then
            echo "MariaDB root password is correct.";
        else
            echo "MariaDB root password incorrect! Please check it and try again!"
            exit 1
        fi
    fi

    read -p "Please input the database name:" dbname
    read -p "Please set the password for user $dbname:" mysqlpwd
    create="y"
    break
    ;;
    n|N|no|NO|No)
    echo "Not create database, you entered $create"
    create="n"
    break
    ;;
    *) echo "Please input only y or n"
    esac
    done

    # Create database
    if [ "$create" == "y" ];then
    mysql -uroot -p$mysqlroot_passwd  <<EOF
CREATE DATABASE IF NOT EXISTS \`$dbname\`;
GRANT ALL PRIVILEGES ON \`$dbname\` . * TO '$dbname'@'localhost' IDENTIFIED BY '$mysqlpwd';
GRANT ALL PRIVILEGES ON \`$dbname\` . * TO '$dbname'@'127.0.0.1' IDENTIFIED BY '$mysqlpwd';
GRANT ALL PRIVILEGES ON \`phpmyadmin\` . * TO '$dbname'@'localhost' IDENTIFIED BY '$mysqlpwd';
GRANT ALL PRIVILEGES ON \`phpmyadmin\` . * TO '$dbname'@'127.0.0.1' IDENTIFIED BY '$mysqlpwd';
FLUSH PRIVILEGES;
EOF
    fi
    # Define website dir
    webdir="/data/www/$domain"
    DocumentRoot="$webdir/web"
    logsdir="$webdir/logs"
    mkdir -p $DocumentRoot $logsdir
    chown -R apache:apache $webdir
    # Create vhost configuration file
    cat >/usr/local/apache/conf/vhost/$domain.conf<<EOF
<virtualhost *:80>
ServerName  $domain
ServerAlias  $domains 
DocumentRoot  $DocumentRoot
CustomLog $logsdir/access.log combined
DirectoryIndex index.php index.html
<Directory $DocumentRoot>
Options +Includes -Indexes
AllowOverride All
Order Deny,Allow
Allow from All
php_admin_value open_basedir $DocumentRoot:/tmp
</Directory>
</virtualhost>
EOF
    /etc/init.d/httpd restart > /dev/null 2>&1
    echo "Successfully create $domain vhost"
    echo "######################### information about your website ############################"
    echo "The DocumentRoot:$DocumentRoot"
    echo "The Logsdir:$logsdir"
    [ "$create" == "y" ] && echo "database name and user:$dbname, password:$mysqlpwd"
}

# Remove apache virtualhost
function vhost_del(){
    read -p "Please input a domain you want to delete:" vhost_domain
    if [ -z "$vhost_domain" ]; then
        echo "You need input a domain."
        exit 1
    fi
    echo "---------------------------"
    echo "vhost account = $vhost_domain"
    echo "---------------------------"
    echo ""
    get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
    }
    echo "Press any key to start delete vhost..."
    echo "or Press Ctrl+c to cancel"
    echo ""
    char=`get_char`

    if [ -f "/usr/local/apache/conf/vhost/$vhost_domain.conf" ]; then
        rm -rf /usr/local/apache/conf/vhost/$vhost_domain.conf
    else
        echo "Error! No such domain file. Please check your input domain again."
        exit 1
    fi

    /etc/init.d/httpd restart > /dev/null 2>&1
    echo "Successfully delete $vhost_domain vhost"
    echo "You need to remove site directory manually!"
}

# List apache virtualhost
function vhost_list(){
    ls /usr/local/apache/conf/vhost/ | grep -v "none.conf" | awk -F".conf" '{print $1}'
}

# add,del,list ftp user
function ftp(){
    if [ ! -f /etc/init.d/pure-ftpd ];then
        echo "Error: pure-ftpd not installed, please install it at first."
        echo "Execute command: ./pureftpd.sh and install pure-ftpd."
        exit 1
    fi
    case "$faction" in
    add)
    read -p "Please input ftpuser name:" ftpuser
    read -p "Please input ftpuser password:" ftppwd
    read -p "Please input ftpuser root directory:" ftproot
    useradd -d $ftproot -g ftp -c pure-ftpd -s /sbin/nologin  $ftpuser
    echo $ftpuser:$ftppwd |chpasswd
    if [ -d "$ftproot" ]; then
        chmod -R 755 $ftproot
        chown -R $ftpuser:ftp $ftproot
    else
        mkdir -p $ftproot
        chmod -R 755 $ftproot
        chown -R $ftpuser:ftp $ftproot
    fi
    echo "Successfully create ftpuser $ftpuser"
    echo "ftp root directory is $ftproot"
    ;;
    del)
    read -p "Please input the ftpuser you want to delete:" ftpuser
    userdel $ftpuser
    echo "Successfully delete ftpuser $ftpuser"
    ;;
    list)
    printf "FTPUser\t\tRoot Directory\n"
    cat /etc/passwd | grep pure-ftpd | awk 'BEGIN {FS=":"} {print $1"\t\t"$6}'
    ;;
    *)
    echo "Usage:add|del|list"
    exit 1
    esac
}

# Install LAMP Script
function install_lamp(){
    rootness
    check_sys
    disable_selinux
    pre_installation_settings
    download_all_files
    untar_all_files
    install_pcre
    install_apache
    install_database
    install_libiconv
    install_libmcrypt
    install_mhash
    install_mcrypt
    install_re2c
    install_libedit
    install_imap
    install_php
    install_phpmyadmin
    install_cleanup
}

# Initialization setup
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_lamp
    ;;
uninstall)
    uninstall_lamp
    ;;
add)
   vhost_add
    ;;
del)
   vhost_del
    ;;
list)
   vhost_list
    ;;
ftp)
  faction=$2
    ftp
        ;;
*)
    echo "Usage: `basename $0` {install|uninstall|add|del|list|ftp(add,del,list)}"
    ;;
esac
