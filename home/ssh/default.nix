{ config, pkgs, lib, ... }:
{
   config = {
      programs.ssh = {
         enable = true;
         forwardAgent = true;
         extraConfig = ''
            StrictHostKeyChecking=accept-new
            IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
            User james.maes
            Port 10022
         '';


         matchBlocks = {

            ####################
            ## External Sites ##
            ####################
            "github.com"   = { port = 22; hostname = "github.com";   user = "git"; };
            "git.qrun.io"  = { port = 22; hostname = "git.qrun.io";  user = "git"; };



            ####################################################################################################
            ## ------------------------------------ Coldtrack Hosts ----------------------------------------- ##
            ####################################################################################################

            #######################
            ## Coldtrack Network ##
            #######################
            lab1-fw-ha        = { host = "lab1-fw-ha lab1-fw-ha.galaxy.lan"; port = 10022; hostname = "10.100.193.12";                                 user = "jmaes"; };
            edison-fs1        = { host = "edison-fs1 edison-fs1.galaxy.lan"; port = 10022; hostname = "10.1.0.5";                                      user = "jmaes"; };
            p-switch01        = { host = "p-switch01 p-switch01.galaxy.lan"; port = 10022; hostname = "p-switch01.internal.edison.coldtrack.com";      user = "jmaes"; };
            p1-node           = { host = "p1-node p1-node.galaxy.lan"; port = 10022; hostname = "p1-node.internal.edison.coldtrack.com";         user = "local_admin"; };
            p2-node           = { host = "p2-node p2-node.galaxy.lan"; port = 10022; hostname = "p2-node.internal.edison.coldtrack.com";         user = "local_admin"; };
            master01-cci-d    = { host = "master01-cci-d master01-cci-d.galaxy.lan"; port = 10022; hostname = "master01-cci-d.cci-dev.coldtrack.com.com";      user = "james.maes"; };
            master01-cci-s    = { host = "master01-cci-s master01-cci-s.galaxy.lan"; port = 10022; hostname = "master01-cci-s.cci-staging.coldtrack.com.com";  user = "james.maes"; };
            master01-cci-p    = { host = "master01-cci-p master01-cci-p.galaxy.lan"; port = 10022; hostname = "master01-cci-p.cci-prod.coldtrack.com.com";     user = "james.maes"; };
            storage01-cci-p   = { host = "storage01-cci-p storage01-cci-p.galaxy.lan"; port = 10022; hostname = "storage01-cci-p.cci-prod.coldtrack.com.com";    user = "james.maes"; };
            semaphore01-cci-p = { host = "semaphore01-cci-p semaphore01-cci-p.galaxy.lan"; port = 10022; hostname = "semaphore01-cci-p.cci-prod.coldtrack.com.com";  user = "james.maes"; };
            checkmk01-cci-p   = { host = "checkmk01-cci-p checkmk01-cci-p.galaxy.lan"; port = 10022; hostname = "checkmk01-cci-p.cci-prod.coldtrack.com.com";    user = "james.maes"; };

            #####################################
            ## Coldtrack Department OU Servers ##
            #####################################
            sftp_finance_test                = { host = "sftp_finance_test sftp_finance_test.galaxy.lan"; port = 22; hostname = "sftp.finance.coldtrack.com"; user = "test"; };
            sftp_finance_coldtrack_invoicing = { host = "sftp_finance_coldtrack_invoicing sftp_finance_coldtrack_invoicing.galaxy.lan"; port = 22; hostname = "sftp.finance.coldtrack.com"; user = "coldtrack_invoicing"; };


            
            #################################################################################################
            ## ------------------------------------ Galaxy Hosts ----------------------------------------- ##
            #################################################################################################

            ##########################
            ## Galaxy Network Hosts ##
            ##########################
            ss-100-1 = { host = "ss-100-1 ss-100-1.galaxy.lan"; port = 22; hostname = "ss-100-1.galaxy.lan"; user = "local_admin"; };

            ###########################
            ## Galaxy Synology Hosts ##
            ###########################
            coruscant = { host = "coruscant coruscant.galaxy.lan"; port = 10022; hostname = "coruscant.galaxy.lan";  user = "CoruscantGalaxyAdmin"; };
            emperor   = { host = "emperor emperor.galaxy.lan"; port = 10022; hostname = "emperor.galaxy.lan";    user = "EmperorGalaxyAdmin"; };
            scarif    = { host = "scarif scarif.galaxy.lan"; port = 10022; hostname = "scarif.galaxy.lan";     user = "ScarifGalaxyAdmin"; };

            ############################################
            ## Synology Business Mail / Corp VM Hosts ##
            ############################################
            galaxy-dsm        = { host = "galaxy-dsm galaxy-dsm.galaxy.lan"; port = 10022; hostname = "galaxy-dsm.galaxy.lan";       user = "GalaxyDSMGalaxyAdmin"; };
            kingsrook-dsm     = { host = "kingsrook-dsm kingsrook-dsm.galaxy.lan"; port = 10022; hostname = "kingsrook-dsm.galaxy.lan";    user = "KingsrookGalaxyAdmin"; };
            koftwentytwo-dsm  = { host = "koftwentytwo-dsm koftwentytwo-dsm.galaxy.lan"; port = 10022; hostname = "koftwentytwo-dsm.galaxy.lan"; user = "Kof22GalaxyAdmin"; };
            mmlt-dsm          = { host = "mmlt-dsm mmlt-dsm.galaxy.lan"; port = 10022; hostname = "mmlt-dsm.galaxy.lan";         user = "MMLTGalaxyAdmin"; };
            qrun-dsm          = { host = "qrun-dsm qrun-dsm.galaxy.lan"; port = 10022; hostname = "qrun-dsm.galaxy.lan";         user = "james.maes"; };
            queuedl-dsm       = { host = "queuedl-dsm queuedl-dsm.galaxy.lan"; port = 10022; hostname = "queuedl-dsm.galaxy.lan";      user = "QUEUEDLAdmin"; };
            rcid-dsm          = { host = "rcid-dsm rcid-dsm.galaxy.lan"; port = 10022; hostname = "rcid-dsm.galaxy.lan";         user = "RCIDAdmin"; };

            ##########################
            ## Galaxy Proxmox Hosts ##
            ##########################
            p1  = { host = "p1 p1.galaxy.lan"; port = 10022; hostname = "p1.galaxy.lan";  user = "james.maes"; };
            p2  = { host = "p2 p2.galaxy.lan"; port = 10022; hostname = "p2.galaxy.lan";  user = "james.maes"; };
            p3  = { host = "p3 p3.galaxy.lan"; port = 10022; hostname = "p3.galaxy.lan";  user = "james.maes"; };
            pbs = { host = "pbs pbs.galaxy.lan"; port = 10022; hostname = "pbs.galaxy.lan"; user = "local_admin"; };
            pmg = { host = "pmg pmg.galaxy.lan"; port = 10022; hostname = "pmg.galaxy.lan"; user = "local_admin"; };

            ##########################
            ## Galaxy Network Hosts ##
            ##########################
            cr-100-1  = { host = "cr-100-1 cr-100-1.galaxy.lan"; port = 22; hostname = "cr-100-1.galaxy.lan";  user = "root"; };

            ###########################
            ## galaxy k8s prod plane ##
            ###########################
            k8s-prod-controller-a   = { host = "k8s-prod-controller-a k8s-prod-controller-a.galaxy.lan"; port = 10022; hostname = "k8s-prod-controller-a.k8s.galaxy.lan";    user = "james.maes"; };
            k8s-prod-controller-b   = { host = "k8s-prod-controller-b k8s-prod-controller-b.galaxy.lan"; port = 10022; hostname = "k8s-prod-controller-b.k8s.galaxy.lan";    user = "james.maes"; };
            k8s-prod-controller-c   = { host = "k8s-prod-controller-c k8s-prod-controller-c.galaxy.lan"; port = 10022; hostname = "k8s-prod-controller-c.k8s.galaxy.lan";    user = "james.maes"; };
            k8s-prod-worker-a-1     = { host = "k8s-prod-worker-a-1 k8s-prod-worker-a-1.galaxy.lan"; port = 10022; hostname = "k8s-prod-worker-a-1.k8s.galaxy.lan";      user = "james.maes"; };
            k8s-prod-worker-a-2     = { host = "k8s-prod-worker-a-2 k8s-prod-worker-a-2.galaxy.lan"; port = 10022; hostname = "k8s-prod-worker-a-2.k8s.galaxy.lan";      user = "james.maes"; };
            k8s-prod-worker-b-1     = { host = "k8s-prod-worker-b-1 k8s-prod-worker-b-1.galaxy.lan"; port = 10022; hostname = "k8s-prod-worker-b-1.k8s.galaxy.lan";      user = "james.maes"; };
            k8s-prod-worker-b-2     = { host = "k8s-prod-worker-b-2 k8s-prod-worker-b-2.galaxy.lan"; port = 10022; hostname = "k8s-prod-worker-b-2.k8s.galaxy.lan";      user = "james.maes"; };
            k8s-prod-worker-c-1     = { host = "k8s-prod-worker-c-1 k8s-prod-worker-c-1.galaxy.lan"; port = 10022; hostname = "k8s-prod-worker-c-1.k8s.galaxy.lan";      user = "james.maes"; };
            k8s-prod-worker-c-2     = { host = "k8s-prod-worker-c-2 k8s-prod-worker-c-2.galaxy.lan"; port = 10022; hostname = "k8s-prod-worker-c-2.k8s.galaxy.lan";      user = "james.maes"; };

            #############################
            ## galaxy k8s secure plane ##
            #############################
            k8s-secure-ctl-0-m   = { host = "k8s-secure-ctl-0-m k8s-secure-ctl-0-m.galaxy.lan"; port = 10022; hostname = "k8s-secure-ctl-0-m.k8s.galaxy.lan";    user = "james.maes"; };
            k8s-secure-ctl-0-s   = { host = "k8s-secure-ctl-0-s k8s-secure-ctl-0-s.galaxy.lan"; port = 10022; hostname = "k8s-secure-ctl-0-s.k8s.galaxy.lan";    user = "james.maes"; };
            k8s-secure-ctl-1-s   = { host = "k8s-secure-ctl-1-s k8s-secure-ctl-1-s.galaxy.lan"; port = 10022; hostname = "k8s-secure-ctl-1-s.k8s.galaxy.lan";    user = "james.maes"; };
            k8s-secure-worker-0  = { host = "k8s-secure-worker-0 k8s-secure-worker-0.galaxy.lan"; port = 10022; hostname = "k8s-secure-worker-0.k8s.galaxy.lan";   user = "james.maes"; };
            k8s-secure-worker-1  = { host = "k8s-secure-worker-1 k8s-secure-worker-1.galaxy.lan"; port = 10022; hostname = "k8s-secure-worker-1.k8s.galaxy.lan";   user = "james.maes"; };
            k8s-secure-worker-2  = { host = "k8s-secure-worker-2 k8s-secure-worker-2.galaxy.lan"; port = 10022; hostname = "k8s-secure-worker-2.k8s.galaxy.lan";   user = "james.maes"; };
            k8s-secure-worker-3  = { host = "k8s-secure-worker-3 k8s-secure-worker-3.galaxy.lan"; port = 10022; hostname = "k8s-secure-worker-3.k8s.galaxy.lan";   user = "james.maes"; };
            k8s-secure-worker-4  = { host = "k8s-secure-worker-4 k8s-secure-worker-4.galaxy.lan"; port = 10022; hostname = "k8s-secure-worker-4.k8s.galaxy.lan";   user = "james.maes"; };
            k8s-secure-worker-5  = { host = "k8s-secure-worker-5 k8s-secure-worker-5.galaxy.lan"; port = 10022; hostname = "k8s-secure-worker-5.k8s.galaxy.lan";   user = "james.maes"; };

            ########################
            ## Mysql DB Cluster A ##
            ########################
            mysql-db-a-proxy     = { host = "mysql-db-a-proxy mysql-db-a-proxy.galaxy.lan"; port = 10022; hostname = "mysql-db-a-proxy.galaxy.lan";          user = "james.maes"; };
            mysql-db-a-1         = { host = "mysql-db-a-1 mysql-db-a-1.galaxy.lan"; port = 10022; hostname = "mysql-db-a-1.galaxy.lan";              user = "james.maes"; };
            mysql-db-a-2         = { host = "mysql-db-a-2 mysql-db-a-2.galaxy.lan"; port = 10022; hostname = "mysql-db-a-2.galaxy.lan";              user = "james.maes"; };
            mysql-db-a-3         = { host = "mysql-db-a-3 mysql-db-a-3.galaxy.lan"; port = 10022; hostname = "mysql-db-a-3.galaxy.lan";              user = "james.maes"; };

            ###########################
            ## Postgres DB Cluster A ##
            ###########################
            pg-db-a-1              = { host = "pg-db-a-1 pg-db-a-1.galaxy.lan"; port = 10022; hostname = "pg-db-a-1.galaxy.lan";               user = "james.maes";  };

            ####################
            ## Galaxy.Lan VMs ##  
            ####################
            ansible-controller     = { host = "ansible-controller ansible-controller.galaxy.lan"; port = 10022; hostname = "ansible-controller.galaxy.lan";      user = "local_admin"; };
            ca                     = { host = "ca ca.galaxy.lan"; port = 10022; hostname = "ca.galaxy.lan";                      user = "james.maes";  };
            checkmk                = { host = "checkmk checkmk.galaxy.lan"; port = 10022; hostname = "checkmk.galaxy.lan";                 user = "local_admin"; };
            coturn                 = { host = "coturn coturn.galaxy.lan"; port = 10022; hostname = "coturn.galaxy.lan";                  user = "james.maes";  };
            dba                    = { host = "dba dba.galaxy.lan"; port = 10022; hostname = "dba.galaxy.lan";                     user = "james.maes";  };
            docker-registry-mirror = { host = "docker-registry-mirror docker-registry-mirror.galaxy.lan"; port = 10022; hostname = "docker-registry-mirror.galaxy.lan";  user = "local_admin"; };
            graylog                = { host = "graylog graylog.galaxy.lan"; port = 10022; hostname = "graylog.galaxy.lan";                 user = "local_admin"; };
            influx-db1             = { host = "influx-db1 influx-db1.galaxy.lan"; port = 10022; hostname = "influx-db1.galaxy.lan";              user = "local_admin"; };
            logs                   = { host = "logs logs.galaxy.lan"; port = 10022; hostname = "logs.galaxy.lan";                    user = "local_admin"; };

            #############################
            ## Galaxy.Lan Workstations ##
            #############################
            count-dooku = { host = "count-dooku count-dooku.galaxy.lan"; port = 10022; hostname = "count-dooku.galaxy.lan";  user = "james.maes"; };
            darth       = { host = "darth darth.galaxy.lan"; port = 10022; hostname = "darth.galaxy.lan";        user = "james.maes"; };
            grogu       = { host = "grogu grogu.galaxy.lan"; port = 10022; hostname = "grogu.galaxy.lan";        user = "james.maes"; };
            jakku       = { host = "jakku jakku.galaxy.lan"; port = 10022; hostname = "jakku.galaxy.lan";        user = "james.maes"; };
            
            #############################
            ## Galaxy Dev Workstations ##
            #############################
            dev-workstation-1       = { host = "dev-workstation-1 dev-workstation-1.galaxy.lan"; port = 10022; hostname = "dev-workstation-1.galaxy.lan";   user = "james.maes"; };
         };
      };
   };
}
