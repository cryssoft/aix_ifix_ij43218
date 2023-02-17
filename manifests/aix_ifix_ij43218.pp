#
#
#-------------------------------------------------------------------------------
#
#  From Advisory.asc:
#
#       Fileset                 Lower Level  Upper Level KEY 
#       ---------------------------------------------------------
#       X11.base.lib            7.1.5.0      7.1.5.34    key_w_fs
#       X11.base.lib            7.2.5.0      7.2.5.1     key_w_fs
#       X11.base.lib            7.2.5.100    7.2.5.100   key_w_fs
#       X11.base.lib            7.3.0.0      7.3.0.0     key_w_fs
#
#       AIX Level APAR     Availability  SP        KEY
#       -----------------------------------------------------
#       7.1.5     IJ43073  **            SP11      key_w_apar
#       7.2.5     IJ42677  **            SP05      key_w_apar
#       7.3.0     IJ42939  **            SP03      key_w_apar
#
#       VIOS Level APAR    Availability  SP        KEY
#       -----------------------------------------------------
#       3.1.2      IJ43599 **            3.1.2.50  key_w_apar
#       3.1.3      IJ43218 **            3.1.3.30  key_w_apar
#
#       AIX Level  Interim Fix (*.Z)         KEY
#       ----------------------------------------------
#       7.1.5.8    IJ43073sAa.221227.epkg.Z  key_w_fix
#       7.1.5.9    IJ43073sAa.221227.epkg.Z  key_w_fix
#       7.1.5.10   IJ43073sAa.221227.epkg.Z  key_w_fix
#       7.2.5.3    IJ42677s4a.221227.epkg.Z  key_w_fix
#       7.2.5.4    IJ42677s4a.221227.epkg.Z  key_w_fix
#       7.3.0.1    IJ42939s2a.221227.epkg.Z  key_w_fix
#       7.3.0.2    IJ42939s2a.221227.epkg.Z  key_w_fix
#
#       VIOS Level  Interim Fix (*.Z)         KEY
#       -----------------------------------------------
#       3.1.2.21    IJ43599s2a.221227.epkg.Z  key_w_fix
#       3.1.2.30    IJ43599s2a.221227.epkg.Z  key_w_fix
#       3.1.2.40    IJ43599s2a.221227.epkg.Z  key_w_fix
#       3.1.3.10    IJ43218s4a.221227.epkg.Z  key_w_fix
#       3.1.3.14    IJ43218s4a.221227.epkg.Z  key_w_fix
#       3.1.3.21    IJ43218s4a.221227.epkg.Z  key_w_fix
#
#-------------------------------------------------------------------------------
#
class aix_ifix_ij43218 {

    #  Make sure we can get to the ::staging module (deprecated ?)
    include ::staging

    #  This only applies to AIX and maybe VIOS in later versions
    if ($::facts['osfamily'] == 'AIX') {

        #  Set the ifix ID up here to be used later in various names
        $ifixName = 'IJ43218'

        #  Make sure we create/manage the ifix staging directory
        require profile::aix_file_opt_ifixes

        #
        #  For now, this one only impacts VIOS, but I don't know why.
        #
        if ($::facts['aix_vios']['is_vios']) {

            #
            #  Friggin' IBM...  The ifix ID that we find and capture in the fact has the
            #  suffix allready applied.
            #
            if ($::facts['aix_vios']['version'] in ['3.1.3.14', '3.1.3.21']) {
                $ifixSuffix = 's4a'
                $ifixBuildDate = '221227'
            }
            else {
                $ifixSuffix = 'unknown'
                $ifixBuildDate = 'unknown'
            }

            #  Add the name and suffix to make something we can find in the fact
            $ifixFullName = "${ifixName}${ifixSuffix}"

            #  If we set our $ifixSuffix and $ifixBuildDate, we'll continue
            if (($ifixSuffix != 'unknown') and ($ifixBuildDate != 'unknown')) {

                #  Don't bother with this if it's already showing up installed
                unless ($ifixFullName in $::facts['aix_ifix'].keys) {
 
                    #  Build up the complete name of the ifix staging source and target
                    $ifixStagingSource = "puppet:///modules/profile/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"
                    $ifixStagingTarget = "/opt/ifixes/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"

                    #  Stage it
                    staging::file { "$ifixStagingSource" :
                        source  => "$ifixStagingSource",
                        target  => "$ifixStagingTarget",
                        before  => Exec["emgr-install-${ifixName}"],
                    }

                    #  GAG!  Use an exec resource to install it, since we have no other option yet
                    exec { "emgr-install-${ifixName}":
                        path     => '/bin:/sbin:/usr/bin:/usr/sbin:/etc',
                        command  => "/usr/sbin/emgr -e $ifixStagingTarget",
                        unless   => "/usr/sbin/emgr -l -L $ifixFullName",
                    }

                    #  Explicitly define the dependency relationships between our resources
                    File['/opt/ifixes']->Staging::File["$ifixStagingSource"]->Exec["emgr-install-${ifixName}"]

                }

            }

        }

    }

}
