#!/usr/bin/perl -w

# WARNING: This script comes with no guarantees of
# functionality or *security*. Use at your own risk.
#
# To run long-term, this script should be run in 
# the background as a daemon. This will, however,
# likely cause noticible lag in processing power.
#
# To run a shell command, simply text the command,
# prefaced by a dollar sign '$'. The result will 
# texted back. You can then repeat the process.
#
# WARNING (AGAIN): This is very insecure. It's a fun 
# toy, but should not be used with any remotely 
# visible machine. See the following information for
# all the reasons NOT to use this script:
# http://en.wikipedia.org/wiki/Short_Message_Service#Vulnerabilities

use strict;
use warnings;

use Google::Voice;

# you must create a google voice account
# www.google.com/voice
my $usr   = 'goog user';
my $pass  = 'goog pass';

# replace with your cell number (with leading country code)
# NOTE: NOT your Google Voice number!
my $num   = 12104584011;

my $voice = Google::Voice->new->login($usr, $pass) or 
	die "Google Voice connection failed with user $usr\n";

my ($from,$txt,$cmd);

while(1){
  foreach my $sms ($voice->sms){
    foreach($sms->messages){
      $from = $_->xml->at('.gc-message-sms-from')->text;

      # only process txts from owner that begin with '$'
      if($from =~ m/^\+$num/ && $_->text =~ m/^\$(.*)/){
        $cmd = &trim($1);
	print "Processing $cmd...\n";

	if($cmd =~ m/^cd(.*)/){ # handle cd special case
          $cmd = &trim($1);
          $txt = "$cmd: No such file or directory";
	  
	  if($cmd =~ m/^~(.*)/){ # handle cd ~(.*)
            $cmd = "$ENV{'HOME'}$1";
	  } else { # normal
            $cmd = $1;
          }
          print "  cd $cmd\n";

          if($cmd){ # dir given
            $txt = `pwd` if chdir $cmd;
          } else { # no dir given
            $txt = `pwd` if chdir;
	  }
        
        } else { # handle everything else
          $txt = `$cmd`;
        }

        $sms->delete;
        $voice->send_sms($num => $txt);
      }
    }
  }
  sleep 10;
}

sub trim($){
  my $s = shift;
  $s =~ s/^\s+//;
  $s =~ s/\s+$//;
  return $s;
}
