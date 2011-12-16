#!/bin/sh

set -ex

MOCK="$1"

# Swift dependencies
$MOCK --chroot "easy_install-2.6 -vvv -H None -f /eggs -z \
                configobj==4.7.2 \
                netaddr==0.7.5 \
                simple_json==1.1 \
                simplejson==2.1.2 \
                xattr==0.6.1
"
