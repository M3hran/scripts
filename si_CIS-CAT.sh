#!/bin/sh

JAVA=java
MAX_RAM_IN_MB=768
DEBUG=0
DATE=$(date +"%m-%d-%y %T")
WORKDIR=/root/cis-cat-full
BENCHDIR=$WORKDIR/benchmarks
LOGFILE=$WORKDIR/scan.log

RH7=CIS_Red_Hat_Enterprise_Linux_7_Benchmark_v2.1.0-xccdf.xml
RH6=CIS_Red_Hat_Enterprise_Linux_6_Benchmark_v2.0.1-xccdf.xml
RH5=CIS_Red_Hat_Enterprise_Linux_5_Benchmark_v2.2.0-xccdf.xml
CENT5=CIS_CentOS_Linux_5_Benchmark_v2.2.0-xccdf.xml
SOL10=CIS_Oracle_Solaris_10_Benchmark_v5.2.0.xml
SOL2=CIS_Oracle_Solaris_2.5.1-9_Benchmark_v1.3.0.xml

which $JAVA 2>&1 > /dev/null

if [ $? -ne "0" ]; then
        echo "Error: Java is not in the system PATH."
        exit 1
fi

JAVA_VERSION_RAW=`$JAVA -version 2>&1`

echo $JAVA_VERSION_RAW | grep -i 'version' | grep '[1]\.[678]\.[0-9]' 2>&1 > /dev/null

if [ $? -eq "1" ]; then

        echo "Error: The version of Java you are attempting to use is not compatible with CISCAT:"
        echo ""
        echo $JAVA_VERSION_RAW
        echo ""
        echo "You must use Java 1.6.x, 1.7.x, or 1.8.x. The most recent version of Java is recommended."
        exit 1;
fi

VER=$(rpm -q --queryformat '%{VERSION}' $(rpm -qa '(redhat|sl|slf|centos|oraclelinux)-release(|-server|-workstation|-client|-computenode)')| cut -c-1)
DIST=$(rpm -q --queryformat '%{NAME}' $(rpm -qa '(redhat|sl|slf|centos|oraclelinux)-release(|-server|-workstation|-client|-computenode)'))


if [[ $DIST =~ .*redhat.* ]]; then
case "$VER" in

  7)
        BENCHFILE=$BENCHDIR/$RH7
  ;;
  6)
        BENCHFILE=$BENCHDIR/$RH6
  ;;
  5)

        BENCHFILE=$BENCHDIR/$RH5
  ;;
  *)
        printf "$DATE Usupported RedHat version: $VER\n" | tee -ai $LOGFILE
        exit 1
  ;;
  esac

elif [[ $DIST =~ .*centos.* ]]; then
case "$VER" in

   5)
        BENCHFILE=$BENCHDIR/$CENT5
   ;;
   *)
        printf "$DATE Usupported CentOS version: $VER\n" | tee -ai $LOGFILE
        exit 1
  ;;
esac
elif [[ $DIST =~ .*oracle.* ]]; then
case "$VER" in

   1)
        BENCHFILE=$BENCHDIR/$ORACLE10
   ;;
   2)
        BENCHFILE=$BENCHDIR/$ORACLE2
   ;;
   *)
        printf "$DATE Usupported Solaris version: $VER\n" | tee -ai $LOGFILE
        exit 1
   ;;
esac
else
        printf "$DATE Usupported Distro: $DIST\n" | tee -ai $LOGFILE
        exit 1
fi

printf "$DATE Using: $BENCHFILE\n" | tee -ai $LOGFILE

if [ $DEBUG -eq "1" ]; then
        $JAVA -Xmx${MAX_RAM_IN_MB}M -jar $WORKDIR/CISCAT.jar $BENCHFILE "$@" --verbose
else
        $JAVA -Xmx${MAX_RAM_IN_MB}M -jar $WORKDIR/CISCAT.jar $BENCHFILE "$@"
fi


