#!/usr/bin/env perl
#

BEGIN{
    unshift @INC,".";
}

use strict;
use warnings;
use Try;

use Data::Dumper;

sub mysub {
    print "mysub()\n";
    die "die in mysub()";
}

my  $trysub = sub{
    print "trysub()\n";
    die "die in trysub()";
};

my $catchsub = sub{
    print "catchsub()\n";
}; 

#my  $v = &mysub;
#print Dumper($v);
#my $v = \&mysub;
#print Dumper($v);


    try {
        die "die out trytest";
    }
    catch {
        print STDERR "EXCEPTION : $_";
    };

sub trytest {
    try {
        die "die in trytest";
    }
    catch {
        print STDERR "EXCEPTION : $_";
        return  1;
    }
    finally {
        print STDERR "FINALLY : 1\n";
    }
    finally {
        print STDERR "FINALLY : 2\n";
    }
    finally {
        print STDERR "FINALLY : 3\n";
    }
    ;

    return  0
}

my $n=trytest();
print STDERR "N=$n\n";

exit(0);


my  $try_result;

$try_result = try { mysub } catch { print STDERR "CATCH: $_ !!!\n"; };
print STDERR "TRY RESULT : $try_result\n";
$try_result = try { my $i=0 } catch { print STDERR "CATCH: $_ !!!\n"; };
print STDERR "TRY RESULT : $try_result\n";

exit(0);




$try_result = &try( $trysub, catch { print STDERR "CATCH: $@ !!!\n"; $catchsub->() } );
print STDERR "TRY RESULT : $try_result\n";
$try_result = try { $trysub } catch { print STDERR "CATCH: $@ !!!\n"; $catchsub->() };
print STDERR "TRY RESULT : $try_result\n";
$try_result = try( sub {die "die in try"} , catch { print STDERR "CATCH: $@ !!!\n"; $catchsub->() } );
print STDERR "TRY RESULT : $try_result\n";
$try_result = try( \&mysub, catch { print STDERR "CATCH: $@ !!!\n"; $catchsub->() } );
print STDERR "TRY RESULT : $try_result\n";


my $m;
#try sub{},sub{};

#$cb->();

my $a;
my $b;
my $c;

sub mylink($$){
}

mylink $a ,$b; 
&mylink($a,$b,$c);  

sub lsm(&;@){
}

lsm sub{},$c;
#lsm $a , $b;
&lsm(sub{},$c); # 


