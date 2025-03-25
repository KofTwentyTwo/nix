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
            lab1-fw-ha        = { port = 10022; hostname = "10.100.193.12";                                 user = "jmaes"; };
            edison-fs1        = { port = 10022; hostname = "10.1.0.5";                                      user = "jmaes"; };
            p-switch01        = { port = 10022; hostname = "p-switch01.internal.edison.coldtrack.com";      user = "jmaes"; };
            p1-node           = { port = 10022; hostname = "p1-node.internal.edison.coldtrack.com";         user = "local_admin"; };
            p2-node           = { port = 10022; hostname = "p2-node.internal.edison.coldtrack.com";         user = "local_admin"; };
            master01-cci-d    = { port = 10022; hostname = "master01-cci-d.cci-dev.coldtrack.com.com";      user = "james.maes"; };
            master01-cci-s    = { port = 10022; hostname = "master01-cci-s.cci-staging.coldtrack.com.com";  user = "james.maes"; };
            master01-cci-p    = { port = 10022; hostname = "master01-cci-p.cci-prod.coldtrack.com.com";     user = "james.maes"; };
            storage01-cci-p   = { port = 10022; hostname = "storage01-cci-p.cci-prod.coldtrack.com.com";    user = "james.maes"; };
            semaphore01-cci-p = { port = 10022; hostname = "semaphore01-cci-p.cci-prod.coldtrack.com.com";  user = "james.maes"; };
            checkmk01-cci-p   = { port = 10022; hostname = "checkmk01-cci-p.cci-prod.coldtrack.com.com";    user = "james.maes"; };

            #####################################
            ## Coldtrack Department OU Servers ##
            #####################################
            sftp_finance_test                = { port = 22; hostname = "sftp.finance.coldtrack.com"; user = "test"; };
            sftp_finance_coldtrack_invoicing = { port = 22; hostname = "sftp.finance.coldtrack.com"; user = "coldtrack_invoicing"; };


            
            #################################################################################################
            ## ------------------------------------ Galaxy Hosts ----------------------------------------- ##
            #################################################################################################

            ##########################
            ## Galaxy Network Hosts ##
            ##########################
            ss-100-1 = { port = 22; hostname = "ss-100-1.galaxy.lan"; user = "local_admin"; };

            ###########################
            ## Galaxy Synology Hosts ##
            ###########################
            coruscant = { port = 10022; hostname = "coruscant.galaxy.lan";  user = "CoruscantGalaxyAdmin"; };
            emperor   = { port = 10022; hostname = "emperor.galaxy.lan";    user = "EmperorGalaxyAdmin"; };
            scarif    = { port = 10022; hostname = "scarif.galaxy.lan";     user = "ScarifGalaxyAdmin"; };

            ############################################
            ## Synology Business Mail / Corp VM Hosts ##
            ############################################
            galaxy-dsm        = { port = 10022; hostname = "galaxy-dsm.galaxy.lan";       user = "GalaxyDSMGalaxyAdmin"; };
            kingsrook-dsm     = { port = 10022; hostname = "kingsrook-dsm.galaxy.lan";    user = "KingsrookGalaxyAdmin"; };
            koftwentytwo-dsm  = { port = 10022; hostname = "koftwentytwo-dsm.galaxy.lan"; user = "Kof22GalaxyAdmin"; };
            mmlt-dsm          = { port = 10022; hostname = "mmlt-dsm.galaxy.lan";         user = "MMLTGalaxyAdmin"; };
            qrun-dsm          = { port = 10022; hostname = "qrun-dsm.galaxy.lan";         user = "james.maes"; };
            queuedl-dsm       = { port = 10022; hostname = "queuedl-dsm.galaxy.lan";      user = "QUEUEDLAdmin"; };
            rcid-dsm          = { port = 10022; hostname = "rcid-dsm.galaxy.lan";         user = "RCIDAdmin"; };

            ##########################
            ## Galaxy Proxmox Hosts ##
            ##########################
            p1  = { port = 10022; hostname = "p1.galaxy.lan";  user = "james.maes"; };
            p2  = { port = 10022; hostname = "p2.galaxy.lan";  user = "james.maes"; };
            p3  = { port = 10022; hostname = "p3.galaxy.lan";  user = "james.maes"; };
            pbs = { port = 10022; hostname = "pbs.galaxy.lan"; user = "local_admin"; };
            pmg = { port = 10022; hostname = "pmg.galaxy.lan"; user = "local_admin"; };

            ##########################
            ## Galaxy Network Hosts ##
            ##########################
            cr-100-1  = { port = 22; hostname = "cr-100-1.galaxy.lan";  user = "root"; };

            ###########################
            ## galaxy k8s prod plane ##
            ###########################
            k8s-prod-controller-a   = { port = 10022; hostname = "k8s-prod-controller-a.k8s.galaxy.lan";    user = "james.maes"; };
            k8s-prod-controller-b   = { port = 10022; hostname = "k8s-prod-controller-b.k8s.galaxy.lan";    user = "james.maes"; };
            k8s-prod-controller-c   = { port = 10022; hostname = "k8s-prod-controller-c.k8s.galaxy.lan";    user = "james.maes"; };
            k8s-prod-worker-a-1     = { port = 10022; hostname = "k8s-prod-worker-a-1.k8s.galaxy.lan";      user = "james.maes"; };
            k8s-prod-worker-a-2     = { port = 10022; hostname = "k8s-prod-worker-a-2.k8s.galaxy.lan";      user = "james.maes"; };
            k8s-prod-worker-b-1     = { port = 10022; hostname = "k8s-prod-worker-b-1.k8s.galaxy.lan";      user = "james.maes"; };
            k8s-prod-worker-b-2     = { port = 10022; hostname = "k8s-prod-worker-b-2.k8s.galaxy.lan";      user = "james.maes"; };
            k8s-prod-worker-c-1     = { port = 10022; hostname = "k8s-prod-worker-c-1.k8s.galaxy.lan";      user = "james.maes"; };
            k8s-prod-worker-c-2     = { port = 10022; hostname = "k8s-prod-worker-c-2.k8s.galaxy.lan";      user = "james.maes"; };

            #############################
            ## galaxy k8s secure plane ##
            #############################
            k8s-secure-ctl-0-m   = { port = 10022; hostname = "k8s-secure-ctl-0-m.k8s.galaxy.lan";    user = "james.maes"; };
            k8s-secure-ctl-0-s   = { port = 10022; hostname = "k8s-secure-ctl-0-s.k8s.galaxy.lan";    user = "james.maes"; };
            k8s-secure-ctl-1-s   = { port = 10022; hostname = "k8s-secure-ctl-1-s.k8s.galaxy.lan";    user = "james.maes"; };
            k8s-secure-worker-0  = { port = 10022; hostname = "k8s-secure-worker-0.k8s.galaxy.lan";   user = "james.maes"; };
            k8s-secure-worker-1  = { port = 10022; hostname = "k8s-secure-worker-1.k8s.galaxy.lan";   user = "james.maes"; };
            k8s-secure-worker-2  = { port = 10022; hostname = "k8s-secure-worker-2.k8s.galaxy.lan";   user = "james.maes"; };
            k8s-secure-worker-3  = { port = 10022; hostname = "k8s-secure-worker-3.k8s.galaxy.lan";   user = "james.maes"; };
            k8s-secure-worker-4  = { port = 10022; hostname = "k8s-secure-worker-4.k8s.galaxy.lan";   user = "james.maes"; };
            k8s-secure-worker-5  = { port = 10022; hostname = "k8s-secure-worker-5.k8s.galaxy.lan";   user = "james.maes"; };

            ########################
            ## Mysql DB Cluster A ##
            ########################
            mysql-db-a-proxy     = { port = 10022; hostname = "mysql-db-a-proxy.galaxy.lan";          user = "james.maes"; };
            mysql-db-a-1         = { port = 10022; hostname = "mysql-db-a-1.galaxy.lan";              user = "james.maes"; };
            mysql-db-a-2         = { port = 10022; hostname = "mysql-db-a-2.galaxy.lan";              user = "james.maes"; };
            mysql-db-a-3         = { port = 10022; hostname = "mysql-db-a-3.galaxy.lan";              user = "james.maes"; };

            ###########################
            ## Postgres DB Cluster A ##
            ###########################
            pg-db-a-1              = { port = 10022; hostname = "pg-db-a-1.galaxy.lan";               user = "james.maes";  };

            ####################
            ## Galaxy.Lan VMs ##  
            ####################
            ansible-controller     = { port = 10022; hostname = "ansible-controller.galaxy.lan";      user = "local_admin"; };
            ca                     = { port = 10022; hostname = "ca.galaxy.lan";                      user = "james.maes";  };
            checkmk                = { port = 10022; hostname = "checkmk.galaxy.lan";                 user = "local_admin"; };
            coturn                 = { port = 10022; hostname = "coturn.galaxy.lan";                  user = "james.maes";  };
            dba                    = { port = 10022; hostname = "dba.galaxy.lan";                     user = "james.maes";  };
            docker-registry-mirror = { port = 10022; hostname = "docker-registry-mirror.galaxy.lan";  user = "local_admin"; };
            graylog                = { port = 10022; hostname = "graylog.galaxy.lan";                 user = "local_admin"; };
            influx-db1             = { port = 10022; hostname = "influx-db1.galaxy.lan";              user = "local_admin"; };
            logs                   = { port = 10022; hostname = "logs.galaxy.lan";                    user = "local_admin"; };

            #############################
            ## Galaxy.Lan Workstations ##
            #############################
            count-dooku = { port = 10022; hostname = "count-dooku.galaxy.lan";  user = "james.maes"; };
            darth       = { port = 10022; hostname = "darth.galaxy.lan";        user = "james.maes"; };
            grogu       = { port = 10022; hostname = "grogu.galaxy.lan";        user = "james.maes"; };
            jakku       = { port = 10022; hostname = "jakku.galaxy.lan";        user = "james.maes"; };
         };
      };
   };
}
