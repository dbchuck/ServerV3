#!/usr/bin/env bash

set -x

EMAIL=$1

cat << 'EOF' > /bin/email_login
#!/usr/bin/env bash
# Don't need to monitor cron sessions
if [[ "$PAM_TYPE" == "open_session" ]] && [[ "$PAM_TTY" != "cron" ]]; then {
  if [[ ! -f /tmp/$PPID ]]; then {
    touch /tmp/$PPID
  }
  else {
    # Email has already been sent
    exit 0
  }
  fi
  # start message
  (
  echo "Date: $(date)"
  echo "Server: $(uname -a)"
  echo "Method of login: ${1}"
  echo
  echo
  env
  echo
  echo
  echo "Last 25 lines of /var/log/secure from today:"
  grep "$(date '+%b %_d')" /var/log/secure | tail -n 25
  ) | mail -s "$PAM_USER user login at host: $(hostname -s)" @EMAIL@
}
fi
EOF

sed -i "s/@EMAIL@/$EMAIL/" /bin/email_login
chmod +x /bin/email_login

if [ -f /etc/pam.d/cockpit ]; then
  PAM_FILE='cockpit'
  PAM_STATEMENT="session optional pam_exec.so /bin/email_login $PAM_FILE"
  sed -i "$(grep -n ^session /etc/pam.d/$PAM_FILE | head -n 1 | awk -F: '{print $1}')i $PAM_STATEMENT" /etc/pam.d/$PAM_FILE
fi

for PAM_FILE in login remote runuser runuser-l sshd su su-l sudo sudo-i
do
  PAM_STATEMENT="session optional pam_exec.so /bin/email_login $PAM_FILE"
  sed -i "$(grep -n ^session /etc/pam.d/$PAM_FILE | head -n 1 | awk -F: '{print $1}')i $PAM_STATEMENT" /etc/pam.d/$PAM_FILE
done

for PAM_AC_FILE in system-auth password-auth postlogin
do
  # Remove links to authconfig PAM files
  rm -f /etc/pam.d/$PAM_AC_FILE
  echo "auth include $PAM_AC_FILE-ac" >> /etc/pam.d/$PAM_AC_FILE
  echo "account include $PAM_AC_FILE-ac" >> /etc/pam.d/$PAM_AC_FILE
  echo "password include $PAM_AC_FILE-ac" >> /etc/pam.d/$PAM_AC_FILE
  echo "session include $PAM_AC_FILE-ac" >> /etc/pam.d/$PAM_AC_FILE
  echo "session optional pam_exec.so /bin/email_login $PAM_AC_FILE" >> /etc/pam.d/$PAM_AC_FILE
done
