#!/usr/bin/env perl
#

use strict;
use Redis;
use Getopt::Long;
use Pod::Usage;

my $HOST="127.0.0.1";
my $PORT="6380";
my $help = 0;
my $man = 0;

GetOptions(
	'host=s' =>\$HOST,
	'port=i' =>\$PORT,
	'h|help|?' =>\$help,
	'man' => \$man
	);
pod2usage(1) if $help;
pod2usage(-exitval => 0 , -verbose => 2) if $man;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
$year += 1900;
$mon  += 1;
my $curTime= sprintf "%04d%02d%02d", $year,$mon,$mday; # the diffrent with printf
$curTime=$ARGV[0] if defined($ARGV[0]) ;

my $dayhtml = "daystat.html";
open(my $dayhandle,'>',$dayhtml);

my $hourhtml = "hourstat.html";
open(my $hourhandle,'>',$hourhtml);

# provide seven days data in days and today's data in hour.
# two columnchart 


# get data from redis server 
my $r = Redis->new(server =>"$HOST:$PORT",debug => 0 ); 
my @keys = $r->keys("qss-$curTime*");
my @allkeys = $r->keys("qss-*");
my @days = undef;


@keys = sort {$b cmp $a} @keys;

my $line = "";
my $dl = "";
my $tl = "";
my $rowdata = "";
my $value = undef;

for my $key (@allkeys){
    my $value = substr($key,4,8); 
    push @days,$value;
}

my @unique = undef;
my %count = undef;
@unique = grep { ++$count{$_} < 2 } @days;
@days = sort { $b <=> $a } @unique;
pop @days;
@days = @days[0,1,2,3,4,5,6] if $#days >= 7;

for my $day (@days){
    my @everday = $r->keys("qss-$day*");
    my @field = qw/all add del mod news fast fresh other/;
    my @value;
    for my $hour (@everday){
	my $i = 0;
	while ($i <= $#field){
	   $value[$i] += $r->hget($hour,$field[$i]);
	   $i = $i + 1;
        }
    } 
    $dl = $dl."[ \"$day\",";
    $tl = $tl."[ \"$day\",";   
    for my $v (@value){
	$dl = $dl."$v,";
	$tl = $tl."{v:$v,f:\'$v\'},";
    }
    $dl = $dl."],\n";
    $tl = $tl."],\n";

}


my $dldata = '[
              ["Time", "All", "Add","Del","Mod","News","Fast","Fresh","Other"],'
                ."\n$dl".' 
            ]';
my $htmldata='<html>
<head>
<script type="text/javascript" src="https://www.google.com/jsapi"></script>
<script type="text/javascript">
google.load("visualization", "1", {packages:["corechart"]});
google.load("visualization", "1", {packages:["table"]});
google.setOnLoadCallback(drawChart);
google.setOnLoadCallback(drawTable);
function drawChart() {
    var dldata = google.visualization.arrayToDataTable('.$dldata.');

    var options = {
	title: '."\"Last 7 days Statistic\"".'
    };

    var chart = new google.visualization.LineChart(document.getElementById('."\"chart_div\"".'));
    chart.draw(dldata, options);

}

function drawTable() {
	var data = new google.visualization.DataTable();
	data.addColumn(\'string\',\'Date\');
	data.addColumn(\'number\', \'All\');
	data.addColumn(\'number\', \'Add\');
	data.addColumn(\'number\', \'Del\');
	data.addColumn(\'number\', \'Mod\');
	data.addColumn(\'number\', \'News\');
	data.addColumn(\'number\', \'Fast\');
	data.addColumn(\'number\', \'Fresh\');
	data.addColumn(\'number\', \'Other\');
	data.addRows(['."\n$tl".']);

	var table = new google.visualization.Table(document.getElementById('."\"table_div\"".'));
	table.draw(data, {showRowNumber: false});
}

</script>
</head>
<body>
<div id="chart_div" style="width: 100%; height: 50%;"></div>
<div id="table_div" style="width: 100%; height: 50%;"></div>
</body>
</html>';

print $dayhandle $htmldata; 

# print hourhtml --- 
$dl="";
$tl="";
for my $key (@keys){

    my @field =qw/all add del mod news fast fresh other/;
    #my @value =($ALL,$ADD,$DEL,$MOD,$NEWS,$QUICK,$OTHER,$TIMELINESS);
    my $i = 0;
    $dl = $dl."[ \"$key\",";
    $tl = $tl."[ \"$key\",";
    while($i <= $#field){
        $value = $r->hget($key,$field[$i]);
        $dl = $dl."$value,";
	$tl = $tl."{v:$value,f:\'$value\'},";
        $i = $i + 1;
    }
    $dl = $dl."],\n";
    $tl = $tl."],\n";
}
$dldata = '[
              ["Time", "All", "Add","Del","Mod","News","Fast","Fresh","Other"],'
                ."\n$dl".' 
            ]';
my $htmldata='<html>
<head>
<script type="text/javascript" src="https://www.google.com/jsapi"></script>
<script type="text/javascript">
google.load("visualization", "1", {packages:["corechart"]});
google.load("visualization", "1", {packages:["table"]});
google.setOnLoadCallback(drawChart);
google.setOnLoadCallback(drawTable);
function drawChart() {
    var dldata = google.visualization.arrayToDataTable('.$dldata.');

    var options = {
	title: '."\"Today's Data Statistic\"".'
    };

    var chart = new google.visualization.LineChart(document.getElementById('."\"chart_div\"".'));
    chart.draw(dldata, options);

}

function drawTable() {
	var data = new google.visualization.DataTable();
	data.addColumn(\'string\',\'Date\');
	data.addColumn(\'number\', \'All\');
	data.addColumn(\'number\', \'Add\');
	data.addColumn(\'number\', \'Del\');
	data.addColumn(\'number\', \'Mod\');
	data.addColumn(\'number\', \'News\');
	data.addColumn(\'number\', \'Fast\');
	data.addColumn(\'number\', \'Fresh\');
	data.addColumn(\'number\', \'Other\');
	data.addRows(['."\n$tl".']);

	var table = new google.visualization.Table(document.getElementById('."\"table_div\"".'));
	table.draw(data, {showRowNumber: false});
}

</script>
</head>
<body>
<div id="chart_div" style="width: 100%; height: 50%;"></div>
<div id="table_div" style="width: 100%; height: 50%;"></div>
</body>
</html>';
print $hourhandle $htmldata;


# by lanyun
