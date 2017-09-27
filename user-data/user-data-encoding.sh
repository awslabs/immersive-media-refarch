#!/bin/bash

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

yum -y --security update

yum -y update aws-cli

yum -y install \
  awslogs jq

aws configure set default.region $REGION

cd /tmp && \
  curl -O https://www.johnvansickle.com/ffmpeg/builds/ffmpeg-git-64bit-static.tar.xz && \
  tar Jxf ffmpeg-git-64bit-static.tar.xz && \
  cp -av ffmpeg*/{ff*,qt*} /usr/local/bin

echo '$SystemLogRateLimitInterval 2' >> /etc/rsyslog.conf
echo '$SystemLogRateLimitBurst 500' >> /etc/rsyslog.conf

cp -av immersive-media-refarch/user-data/encoding/awslogs/awslogs.conf /etc/awslogs/
cp -av immersive-media-refarch/user-data/encoding/init/spot-instance-termination-notice-handler.conf /etc/init/spot-instance-termination-notice-handler.conf
cp -av immersive-media-refarch/user-data/encoding/bin/spot-instance-termination-notice-handler.sh /usr/local/bin/

chmod +x /usr/local/bin/spot-instance-termination-notice-handler.sh

sed -i "s|us-east-1|$REGION|g" /etc/awslogs/awscli.conf
sed -i "s|%CLOUDWATCHLOGSGROUP%|$CLOUDWATCHLOGSGROUP|g" /etc/awslogs/awslogs.conf

chkconfig rsyslog on && service rsyslog restart
chkconfig awslogs on && service awslogs restart

start spot-instance-termination-notice-handler

aws s3 cp immersive-media-refarch/user-data/encoding/client/index.html s3://$EGRESSBUCKET/ --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers

/opt/aws/bin/cfn-signal -s true -i $INSTANCE_ID "$WAITCONDITIONHANDLE"
