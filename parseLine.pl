#!/usr/bin/env perl
#

BEGIN{
    unshift @INC,".";
}

use strict;
use warnings;
use Redis;
use Getopt::Long;
use Pod::Usage;


my $HOST="127.0.0.1";
my $PORT="6380";
my $PRODUCT=undef;

my $help = 0;
my $man = 0;
my $psn = 1000;

GetOptions(
        'host=s' => \$HOST,
        'port=i' => \$PORT,
        'product=s' => \$PRODUCT,
        'per-send-num=i' => \$psn,
        'help|?' => \$help, 
        'man' => \$man
        );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

defined($PRODUCT) or die "No product input." ;

my $N_ALL=0;
my $N_ADD=0;
my $N_DEL=0;
my $N_MOD=0;
my $N_NEWS=0;
my $N_FAST=0;
my $N_OTHER=0;
my $N_FRESH=0;

my $lastymdh = getTime()->{ymdh};

while(<STDIN>){
    print $_;
    s/^\s+//g;
    s/\s+$//g;

    $N_ALL++;

    my $curymdh = getTime()->{ymdh};
    if( $curymdh != $lastymdh){
        sendData($HOST,$PORT,$lastymdh);
        $lastymdh = $curymdh;
    }elsif($N_ALL == $psn ){
        sendData($HOST,$PORT,$curymdh);
    }

    my $line = $_;
    if($line =~ /^<flag:1>/){ 
        $N_MOD++;
    }elsif($line =~ /^<flag:2>/){
        $N_DEL++;
    }elsif($line =~ /^<flag:0>/){
        $N_ADD++;
        if($line =~ /><fresh:/){
            $N_FRESH++;
        }elsif($line =~ /><tag:/){
            $N_NEWS++;
        }else{
            $N_FAST++;
        }
    }else{
        $N_OTHER++;
    }

}
sendData($HOST,$PORT,$lastymdh);


# send data to redis  
# handle hincrby failed case.
sub sendData
{
    print STDERR "send...\n";
    my $r = Redis->new(server =>"$HOST:$PORT",debug => 0 ); 
    if($r == 236 ){
        print STDERR "can't connect to server!\n";
        return;
    }
    my $ymdh = getTime()->{ymdh};
    my $key = "$PRODUCT-$ymdh";
    my @field =qw/all add del mod news fast other fresh/;
    my @value =(\$N_ALL,\$N_ADD,\$N_DEL,\$N_MOD,\$N_NEWS,\$N_FAST,\$N_OTHER,\$N_FRESH);

    my $i=0;
    while($i <= $#value){
        my $valueRef = $value[$i];
        my $code = $r->hincrby($key,$field[$i] => $$valueRef);
        $$valueRef = 0 if defined $code;
        $i++;
    }

}


sub printCount
{
    print "$N_ALL\n";
    print "$N_ADD\n";
    print "$N_DEL\n";
    print "$N_MOD\n";
    print "$N_NEWS\n";
    print "$N_FAST\n";
    print "$N_OTHER\n";
    print "$N_FRESH\n";

}

sub getTime
{
    my $time = shift || time();
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);

    $year += 1900;
    $mon ++;

    $min  = '0'.$min  if length($min)  < 2;
    $sec  = '0'.$sec  if length($sec)  < 2;
    $mon  = '0'.$mon  if length($mon)  < 2;
    $mday = '0'.$mday if length($mday) < 2;
    $hour = '0'.$hour if length($hour) < 2;

    my $weekday = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat')[$wday];

    return { 'second' => $sec,
        'minute' => $min,
        'ymdh'   => "$year$mon$mday$hour",
        'hour'   => $hour,
        'day'    => $mday,
        'month'  => $mon,
        'year'   => $year,
        'weekNo' => $wday,
        'wday'   => $weekday,
        'yday'   => $yday,
        'date'   => "$year-$mon-$mday"
    };
}


__END__

=head1 NAME

parseLine.pl -  Count the data and send to redis server 

=head1 SYNOPSIS

parseLine.pl  [options] 

Options:

-host            hostname or ip address on redis server machine

-port            the port that redis server using 

-product         the product name for statistic

-per-send-num    instructions add to the threshold then send to redis server one time 

-help            brief help message

-man             full documentation



=head1 OPTIONS

=over 8

=item B<-host>

hostname or ip address on redis server machine.
    
=item B<-port>

the port that  redis server using.

=item B<-product>

the product name for statistic

=item B<-per-send-num>

instructions add to the threshold then send to redis server one time 

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the stdin and write the stdout ,then count some Counters and  
send to redis Server.

=cut
