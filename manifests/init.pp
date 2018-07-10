# How to launch:
#  /opt/puppetlabs/puppet/bin/puppet apply \
#  --debug --modulepath=/etc/puppetlabs/code/environments/production/modules/ -e "include aixautomation"
# This will trigger this suma command:
#  /usr/sbin/suma -x  -a RqType=SP -a RqName=7200-01-03-1720 -a FilterML=7200-01-02-1717 \
#   -a DisplayName="Downloading lppsources into /tmp/lpp_sources/SP/7200-01-02-1717/7200-01-03-1720" \
#   -a Action=Preview -a DLTarget=/tmp/lpp_sources/SP/7200-01-02-1717/7200-01-03-1720 \
#   -a FilterDir=/tmp/lpp_sources/SP/7200-01-02-1717/7200-01-03-1720
class aixautomation {
  download { "test suma-preview":
    ensure  => present,
    type    => "SP",
    # /tmp should be changed to perform a 'download' to a more appropriate
    #  directory in dedicated file system.
    # No need to change it to perform a 'preview'
    root    => "/tmp",
    from    => "7200-01-02-1717",
    to      => "7200-01-03-1720",
    to_step => "preview",
  }
}