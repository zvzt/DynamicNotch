#!/usr/bin/perl
use strict;
use warnings;
use IO::Select;
use JSON::PP qw(encode_json decode_json);
binmode STDIN;
binmode STDOUT;
$|=1;
my $state="/tmp/dynamicnotch_firefox_state.json";
my $cmd="/tmp/dynamicnotch_firefox_cmd.json";
my $last_id="";
my $sel=IO::Select->new();
$sel->add(\*STDIN);
sub send_msg{my($o)=@_;my $j=encode_json($o);print STDOUT pack("V",length($j)).$j;}
sub read_exact{my($n)=@_;my $buf="";while(length($buf)<$n){my $r=read(STDIN,my $c,$n-length($buf));return undef if !defined($r)||$r==0;$buf.=$c;}return $buf;}
while(1){
  if($sel->can_read(0.10)){
    my $h=read_exact(4);last unless defined $h;my $n=unpack("V",$h);my $j=read_exact($n);last unless defined $j;
    eval{
      my $o=decode_json($j);
      if(($o->{type}//"") eq "media"){
        $o->{time}=time;
        open my $fh,">",$state;
        if($fh){print $fh encode_json($o);close $fh;}
      }
    };
  }
  if(-f $cmd){
    if(open my $fh,"<",$cmd){
      local $/;my $j=<$fh>;close $fh;
      eval{
        my $o=decode_json($j);
        my $id="".($o->{id}//"");
        if($id ne ""&&$id ne $last_id){
          $last_id=$id;
          send_msg({type=>"action",action=>"".($o->{action}//""),value=>$o->{value}});
        }
      };
    }
  }
}