#!/bin/sh

# Copyright The OpenTelemetry Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo ""
echo "=========================================================================="
echo "NRDOT Collector Host installed successfully!"
echo "=========================================================================="
echo ""
echo "Current configuration: DEFAULT (host metrics + logs)"
echo ""
echo "To monitor databases, switch configuration:"
echo "  SQL Server:  sudo cp /etc/nrdot-collector-host/config-sqlserver.yaml /etc/nrdot-collector-host/config.yaml"
echo "  Oracle:      sudo cp /etc/nrdot-collector-host/config-oracle.yaml /etc/nrdot-collector-host/config.yaml"
echo "  Both DBs:    sudo cp /etc/nrdot-collector-host/config-combined.yaml /etc/nrdot-collector-host/config.yaml"
echo ""
echo "After switching configurations:"
echo "  sudo systemctl restart nrdot-collector-host"
echo ""
echo "Configure database credentials using environment variables in:"
echo "  /etc/nrdot-collector-host/nrdot-collector-host.conf"
echo ""
echo "=========================================================================="
echo ""

if command -v systemctl >/dev/null 2>&1; then
    if [ "${NRDOT_MODE}" = "ROOT" ]; then
        sed -i "/User=nrdot-collector-host/d" /lib/systemd/system/nrdot-collector-host.service
        sed -i "/Group=nrdot-collector-host/d" /lib/systemd/system/nrdot-collector-host.service
    fi
    systemctl enable nrdot-collector-host.service
    if [ -f /etc/nrdot-collector-host/config.yaml ]; then
        systemctl start nrdot-collector-host.service
    fi
fi
