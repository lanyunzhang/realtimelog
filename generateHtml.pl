#!/usr/bin/env perl
#

use strict;
use warnings;
use Redis;


my $HOST="127.0.0.1";
my $PORT="6380";
my $KEY=0;
my $ALL=0;
my $ADD=0;
my $DEL=0;
my $MOD=0;
my $NEWS=0;
my $QUICK=0;
my $OTHER=0;
my $TIMELINESS=0;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
$year += 1900;
$mon  += 1;
my $curTime="$year$mon$mday$hour";

my $htmlfile = "googchart.html";
my $successlog= open(my $html,'>',$htmlfile);



# get data from redis server 
my $r = Redis->new(server =>"$HOST:$PORT",debug => 0 ); 
if($r == 236 ){
    print "can't connect to server!\n";
    return;
}
my @keys = $r->keys("log-$year$mon$mday*");
my $line = "";
my $value = undef;

for my $key (@keys){

    my @field =qw/all add del mod news quick timeliness other/;
    #my @value =($ALL,$ADD,$DEL,$MOD,$NEWS,$QUICK,$OTHER,$TIMELINESS);
    my $i = 0;
    my $addline ="[ \"$key\",";
    while($i <= $#field){
        $value = $r->hget($key,$field[$i]);
        $addline = $addline."$value,";
        $i = $i + 1;
    }
    $addline = $addline."],\n";
    $line = $addline.$line;

}

my $data = '[
              ["Time", "All", "Add","Del","Mod","News","Quick","Timeliness","Other"],'
                ."\n$line".' 
            ]';
my $htmldata='<html>
<head>
<script type="text/javascript" src="https://www.google.com/jsapi"></script>
<script type="text/javascript">
google.load("visualization", "1", {packages:["corechart"]});
google.setOnLoadCallback(drawChart);
function drawChart() {
    var data = google.visualization.arrayToDataTable('.$data.');

    var options = {
title: '."\"Real Time Statistic\"".'
    };

    var chart = new google.visualization.LineChart(document.getElementById('."\"chart_div\"".'));
    chart.draw(data, options);
}
</script>
</head>
<body>
<div id="chart_div" style="width: 900px; height: 500px;"></div>
</body>
</html>';

print $html $htmldata; 


