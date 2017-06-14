#!/usr/bin/perl
# MANAGED BY PUPPET

use warnings;
use strict;
	
my $filename = '/SO_logs/btrace/task-mgr.log';
my $outputfile = '/tmp/ingestion.log';
my $flag = 0;
my %guid_hash = ();
open(INPUT_FILE, $filename) or die "Couldn't open $filename for reading you GSPs!";
while (1) {
	my $log = <INPUT_FILE>;
	if( !$log ){
		$flag = 1;
	}
	if( $log && $flag ){
#		print $log;
		if( $log =~ /.*Try to dispatch upload task.*/ ){
#			print "Try to dispatch upload task.\n\n";
			&Dispatch($log);
		}elsif( $log =~ /.*Get upload task result.*/ ){
#			print "Get upload task result.\n\n";
			&Getupload($log);
		}elsif( $log =~ /.*Report successes.*/ ){
#			print "Report successes.\n\n";
			&Report($log);
		}
		&Check_hash;
		&Output_hash;
#		sleep 1;
	}elsif( $flag ){
		sleep 1;
	}
}
close(INPUT_FILE);
sub Output_hash{
#	print "\n---hash---\n";
	open(OF, ">$outputfile") or die "Couldn't open $filename for reading you GSPs!";
	foreach(keys %guid_hash){
		my $guid = $_;
		foreach( keys %{$guid_hash{$guid}} ){
			my $svr_ip = $_;
			print OF "[$guid] [$svr_ip] [$guid_hash{$guid}->{$svr_ip}]\n";
		}
#		print "guidhash: $guid_hash{$guid}\n";
	}
	close(OF);
}

sub Check_hash{
	foreach(keys %guid_hash){
                my $guid = $_;
                foreach( keys %{$guid_hash{$guid}} ){
                        my $svr_ip = $_;
                        my $result = (split(/ /, $guid_hash{$guid}->{$svr_ip}))[-1];
                        my $report = (split(/ /, $guid_hash{$guid}->{$svr_ip}))[1];
			if( $result eq '0' && $report eq 'yes' ){
#	                        print "[$guid] [$svr_ip] [$guid_hash{$guid}->{$svr_ip}] Finished\n";
				delete $guid_hash{$guid}->{$svr_ip};
			}
                }
		if( !(keys %{$guid_hash{$guid}}) ){
#			print "[$guid] Finished\n";
			delete $guid_hash{$guid};
		}
        }
}

sub Dispatch{
	my $str = shift;
#	print "$str";
	my $guid = (split(/=/ , ((split(/,/ , $str))[-1])))[-1];
	chomp($guid);
	my $svr_ip = (split(/ / , (split(/\[|\]/ , $str))[1]))[1];
	my $time = (split(/,/ , $str))[0];
#	print "serverip: $svr_ip\n";
	if ( exists $guid_hash{$guid} ){
#		print "exists guid\n";
		if( exists $guid_hash{$guid}->{$svr_ip} ){
			$guid_hash{$guid}->{$svr_ip} = $time;
		}else{
			$guid_hash{$guid}->{$svr_ip} = $time;
		}
	}else{
		my $guid_status = &new_realsvr;
		$guid_status->{$svr_ip} = $time;
		$guid_hash{$guid} = $guid_status;
	}
}

sub Getupload{
	my $str = shift;
#       print "$str";
	chomp($str);
	my $guid = (split(/=/ , (split(/,/ , $str))[2]))[1];
	my $svr_ip = (split(/,/ , (split(/ / , $str))[9]))[0];
	my $time = (split(/,/ , $str))[0];
	my $result = (split(/=/ , (split(/,/ , $str))[-1]))[1];
###############file exsits######################
	if( $result eq '272302098' ){
		$result = '0';
	}
#	print "guid: $guid  svr_ip: $svr_ip time: $time result: $result\n";
	if( exists $guid_hash{$guid} ){
###############if exists svr_ip, update status, else initial status############################
		if( exists $guid_hash{$guid}->{$svr_ip} ){
			$guid_hash{$guid}->{$svr_ip} = $guid_hash{$guid}->{$svr_ip} .  " Status: $result";
		}else{
			$guid_hash{$guid}->{$svr_ip} = "$time Status: $result";
		}
	}
#	else{
#		$guid_hash{$guid}->{$svr_ip} = "$time Status: $result";
#	}
}

sub Report{
	my $str = shift;
#       print "$str";
	chomp($str);
	my $guid = (split(/=/ , (split(/,/ , $str))[4]))[1];
	if( exists $guid_hash{$guid} ){
#		print "[Report] exists guid: $guid\n";
		foreach(keys %{$guid_hash{$guid}} ){
			my $svr_ip = $_;
#			print "[Report] change report $svr_ip status to yes\n";
			$guid_hash{$guid}->{$svr_ip} = "Report: yes " . "$guid_hash{$guid}->{$svr_ip}";
		}
	}
}


sub new_realsvr{
	return{
	};
}
