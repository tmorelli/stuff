#This script will parse the logs output by garbage collection on ouya
#The output is
#Ctrl1AvgSeekTime,Ctrl1AvgSeekTimeNo0,Ctrl1SeekNo0Count,Ctrl1Search1..5Time,Ctrl1Search1...5Distance


#$filename='1385993701';
$filename=$ARGV[0];
$ctrl[0] = 0;
$ctrl[1] = 0;
$ctrl[2] = 0;

$ctrlIndex = 0;

@avgSeekTime;
@avgSeekTimeNo0;
@avgReactionTime;
@avgReactionTimeNo0;
@seekNo0Count;
@missedCount;
@correctCount;
@totalSeekTimeCorrect;
@searchTime;       #2d array - ctrlType,->time
@searchDistance;   #2d array - ctrlType->distance


###############################################################

sub getControlType{
  my $loc = rindex($_,',')+1;
  my $type = substr($_,$loc,10);
  return $type; 

}

###############################################################
sub getControlSequence(){
  my $totalFound = 0;
  open (MYFILE, $filename);
  while (<MYFILE>) {
    chomp;
    if (index($_,"activeControl") > 1){
      $ctrl[$totalFound] = getControlType($_);
      $totalFound++; 
    }
  }
  close (MYFILE);
  if ($ctrl[2] == 0){
    $ctrl[2] = $ctrl[1];
    $ctrl[1] = $ctrl[0];
    my @xx;
    $xx[0] = 0;
    $xx[1] = 0;
    $xx[2] = 0;
    $xx[$ctrl[1]-1] = 1;
    $xx[$ctrl[2]-1] = 1;
    for ($x = 0; $x<3; $x++){
      if ($xx[$x] == 0){
        $ctrl[0] = $x+1;
        break;
      }
    }

  }
}
###############################################################
sub getMillisFromLine{
  my $start = index($_,',')+1;
  my $end = index($_,',',$start);
  my $millis = substr($_,$start,$end-$start);
  return $millis; 
}
###############################################################
sub getSeekTimes(){
  #times between PlaceNext and OnTarget or BagMissed
  #also need to look for control type switching
#  print ("ControlType: $ctrl[$ctrlIndex]\n");
  $missedCount[$ctrl[$ctrlIndex]-1]=0;

  $correctCount[$ctrl[$ctrlIndex]-1]=0;
  $totalSeekTimeNon0[$ctrl[$ctrlIndex]-1]=0;
  $totalSeekTimeCorrect[$ctrl[$ctrlIndex]-1]=0;
  $correctCountNon0[$ctrl[$ctrlIndex]-1]=0;


  $handledHouse = true;
  open (MYFILE, $filename);
  while (<MYFILE>) {
    chomp;
#    print "$_\n";
    if (index($_,"PlaceNext") > 1){
      $startTime = $time;
      $time = getMillisFromLine($_);
      if ($handledHouse eq false) {
        $time = getMillisFromLine($_);
        my $diff = $time-$startTime;
#        print ("Missed2: $diff\n");
        $missedCount[$ctrl[$ctrlIndex]-1]++;
      }
      $handledHouse = false;
    }
    elsif (index($_,"OnTarget") > 1){
      $startTime = $time;
      $time = getMillisFromLine($_);
      my $diff = $time-$startTime;
#      print ("OnTarget: $diff\n");
      $handledHouse = true;
      $correctCount[$ctrl[$ctrlIndex]-1]++;
      $totalSeekTimeCorrect[$ctrl[$ctrlIndex]-1]+=$diff;
      if ($diff > 250) {
        $totalSeekTimeNon0[$ctrl[$ctrlIndex]-1]+=$diff;
        $correctCountNon0[$ctrl[$ctrlIndex]-1]++;
      }
    }
    elsif (index($_,"BagMissed") > 1){
      $startTime = $time;
      $time = getMillisFromLine($_);
      my $diff = $time-$startTime;
      if ($diff > 1000) {
#        print ("Missed1: $diff\n");
        $handledHouse = true;
        $missedCount[$ctrl[$ctrlIndex]-1]++;
      }
    }
    elsif (index($_,"activeControl") > 1){
      $ctrlIndex++;
#      print ("ControlType: $ctrl[$ctrlIndex]\n");
      $missedCount[$ctrl[$ctrlIndex]-1]=0;
      $correctCount[$ctrl[$ctrlIndex]-1]=0;
      $totalSeekTimeNon0[$ctrl[$ctrlIndex]-1]=0;
      $totalSeekTimeCorrect[$ctrl[$ctrlIndex]-1]=0;
      $correctCountNon0[$ctrl[$ctrlIndex]-1]=0;
    }
  }
  close (MYFILE);
  for ($x = 0; $x < 3; $x ++ )
  { 
    if ($correctCount[$x]> 0){
    	$avgSeekTimeCorrect = $totalSeekTimeCorrect[$x]/$correctCount[$x];
    }
    else{
      $avgSeekTimeCorrect = 0;
    }
    if ($correctCountNon0[$x] > 0){
      $avgSeekTimeNon0 = $totalSeekTimeNon0[$x]/$correctCountNon0[$x];
    }
    else{
      $avgSeekTimeNon0 = 0;
    }
    print($avgSeekTimeCorrect.",".$avgSeekTimeNon0.",".$missedCount[$x].",".$correctCount[$x].",".$correctCountNon0[$x].",");
  }
  print ("\n");
}
###############################################################


getControlSequence();
getSeekTimes();
