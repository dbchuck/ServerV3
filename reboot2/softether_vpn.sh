#!/usr/bin/env bash

set -x

# Build
cd /opt
if [[ ! -f /root/vpnclient.tar.gz ]]; then {
  curl -L https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.29-9680-rtm/softether-vpnclient-v4.29-9680-rtm-2019.02.28-linux-x64-64bit.tar.gz -o vpnclient.tar.gz
  tar xfz vpnclient.tar.gz
  cd vpnclient
  yes 1 | make -j$(nproc)
  if [[ ! -f /opt/vpnclient/vpn_client.config ]]; then {
    # Configuration
    cat << 'EOF' > /opt/vpnclient/vpn_client.config
# Software Configuration File
# ---------------------------
#
# You may edit this file when the VPN Server / Client / Bridge program is not running.
#
# In prior to edit this file manually by your text editor,
# shutdown the VPN Server / Client / Bridge background service.
# Otherwise, all changes will be lost.
#
declare root
{
        bool DisableRelayServer false
        bool DontSavePassword false
        bool EnableVPNGateService false
        byte EncryptedPassword +WzqGYrR3VYXrAhKPZLGEHcIwO8=
        bool HideVPNGateServiceMessage false
        bool PasswordRemoteOnly false
        string UserAgent Mozilla/5.0$20(Windows$20NT$206.3;$20WOW64;$20rv:29.0)$20Gecko/20100101$20Firefox/29.0
        uint UseSecureDeviceId 0

        declare AccountDatabase
        {
                declare Account0
                {
                        bool CheckServerCert false
                        uint64 CreateDateTime 1563980610766
                        uint64 LastConnectDateTime 1564335876059
                        string ShortcutKey 17263111753071648D6AF25274B357EC8730973D
                        bool StartupAccount true
                        uint64 UpdateDateTime 1563980699040

                        declare ClientAuth
                        {
                                uint AuthType 1
                                byte HashedPassword TB1Za8mwnPF9X0dYmpdeSUOq2xc=
                                string Username user
                        }
                        declare ClientOption
                        {
                                string AccountName local
                                uint AdditionalConnectionInterval 1
                                uint ConnectionDisconnectSpan 0
                                string DeviceName nic0
                                bool DisableQoS false
                                bool HalfConnection false
                                bool HideNicInfoWindow false
                                bool HideStatusWindow false
                                string Hostname lol-hax.vpnazure.net
                                string HubName hub0
                                uint MaxConnection 1
                                bool NoRoutingTracking false
                                bool NoTls1 false
                                bool NoUdpAcceleration false
                                uint NumRetry 4294967295
                                uint Port 443
                                uint PortUDP 0
                                string ProxyName $
                                byte ProxyPassword $
                                uint ProxyPort 0
                                uint ProxyType 0
                                string ProxyUsername $
                                bool RequireBridgeRoutingMode false
                                bool RequireMonitorMode false
                                uint RetryInterval 15
                                bool UseCompress false
                                bool UseEncrypt true
                        }
                }
        }
        declare ClientManagerSetting
        {
                bool EasyMode false
                bool LockMode false
        }
        declare CommonProxySetting
        {
                string ProxyHostName $
                uint ProxyPort 0
                uint ProxyType 0
                string ProxyUsername $
        }
        declare Config
        {
                bool AllowRemoteConfig false
                uint64 AutoDeleteCheckDiskFreeSpaceMin 104857600
                string KeepConnectHost keepalive.softether.org
                uint KeepConnectInterval 50
                uint KeepConnectPort 80
                uint KeepConnectProtocol 1
                bool NoChangeWcmNetworkSettingOnWindows8 false
                bool UseKeepConnect false
        }
        declare RootCA
        {
        }
        declare UnixVLan
        {
                declare nic0
                {
                        bool Enabled true
                        string MacAddress 5E-13-E1-95-67-96
                }
        }
}
EOF

  }
  fi
}
fi
/opt/vpnclient/vpnclient start
/opt/vpnclient/vpncmd /CLIENT localhost /CMD accountstartupset local
/opt/vpnclient/vpncmd /CLIENT localhost /CMD accountconnect local
sleep 5
/opt/vpnclient/vpncmd /CLIENT localhost /CMD accountlist

cat << 'EOF' > /usr/lib/systemd/system/vpnclient.service
[Unit]
Description=SoftEther VPN Client
After=network.target

[Service]
Type=forking
ExecStart=/opt/vpnclient/vpnclient start
ExecStop=/opt/vpnclient/vpnclient stop

[Install]
WantedBy=multi-user.target
EOF

cat << 'EOF' > /usr/lib/systemd/system/vpnclient_ip.service
[Unit]
Description=SoftEther VPN Client IP
After=vpnclient.service

[Service]
Type=oneshot
ExecStart=/usr/bin/bash -c 'sleep 1; ip address add 172.16.3.5/24 dev vpn_nic0 || exit 0'

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now vpnclient.service
systemctl enable --now vpnclient_ip.service
