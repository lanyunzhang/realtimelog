#!/usr/bin/env perl
#

BEGIN{
    push @INC,".";
}

use strict;
use warnings;
use Redis;
use Getopt::Long;
use Pod::Usage;


my $HOST="127.0.0.1";
my $PORT="6380";

my $help = 0;
my $man = 0;
my $threshold = 1000000;

GetOptions(
        'host=s' => \$HOST,
        'port=i' => \$PORT,
        'threshold=i' => \$threshold,
        'help|?' => \$help, 
        'man' => \$man
        );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

my $ALL=0;
my $ADD=0;
my $DEL=0;
my $MOD=0;
my $NEWS=0;
my $QUICK=0;
my $OTHER=0;
my $TIMELINESS=0;


my $start = time();
my $date= getTime();
my $lasthour = $date->{hour};

while(<STDIN>){
    $ALL++;
    if($ALL % $threshold == 0 ){
        sendData($HOST,$PORT);
    }
    my $curhour = $date->{hour};
    if( $curhour!= $lasthour ){
        $lasthour = $curhour;
        sendData($HOST,$PORT);
    }

    my $line = $_;
    if($line =~ /<flag:1>/){ 
        $MOD++;
    }elsif($line =~ /<flag:2>/){
        $DEL++;
    }elsif($line =~ /<flag:0>/){
        $ADD++;
        if($line =~ /><fresh:/){
            $TIMELINESS++;
        }elsif($line =~ /><tag:/){
            $NEWS++;
        }else{
            $QUICK++;
        }
    }else{
        $OTHER++;
    }

}
sendData($HOST,$PORT);

my $end = time();
my $last = $end - $start;

#print "ALL is $ALL\n";
#print "ADD is $ADD\n";
#print "DEL is $DEL\n";
#print "MOD is $MOD\n";
#print "NEWS is $NEWS\n";
#print "QUICK is $QUICK\n";
#print "TIMELINESS is $TIMELINESS\n";
#print "OTHER is $OTHER\n";
#print "Spend time is  $last\n";


# send data to redis  
sub sendData
{
    print "send...\n";
    # what if the server is not services ? how to handling the error!
    my $r = Redis->new(server =>"$HOST:$PORT",debug => 0 ); 
    if($r == 236 ){
        print "can't connect to server!\n";
        return;
    }
    my $ymdh = getTime()->{ymdh};
    my $key = "log-$ymdh";
    my @field =qw/all add del mod news quick other timeliness/;
    my @value =($ALL,$ADD,$DEL,$MOD,$NEWS,$QUICK,$OTHER,$TIMELINESS);

    my $i=0;
    while($i<$#value){
        hincrby($r,$key,$field[$i],$value[$i]);
        $i++;
    }
    clearCount();

}

sub hincrby
{
    my ($r,$key,$field,$value) = @_; 
    if ( !$r->hexists($key,$field) ){
        $r->hset($key,$field => 0);
    }

    $r->hincrby($key,$field => $value);
}

sub clearCount
{
    $ALL=0;
    $ADD=0;
    $DEL=0;
    $MOD=0;
    $NEWS=0;
    $QUICK=0;
    $OTHER=0;
    $TIMELINESS=0;

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

-threshold       instructions add to the threshold then send to redis server one time 

-help            brief help message

-man             full documentation



=head1 OPTIONS

=over 8

=item B<-host>

hostname or ip address on redis server machine.
    
=item B<-port>

the port that  redis server using.

=item B<-threshold>

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
