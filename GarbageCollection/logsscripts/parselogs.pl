#This script will parse the logs output by garbage collection on ouya
#The output is
#Ctrl1AvgSeekTime,Ctrl1AvgSeekTimeNo0,Ctrl1SeekNo0Count,Ctrl1Search1..5Time,Ctrl1Search1...5Distance

use POSIX ();
use Math::Complex;

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
sub getBagIndexFromLine{
  my $loc = rindex($_,',')+1;
  my $idx = substr($_,$loc,10);
  return $idx; 
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
      $avgSeekTimeNon0 = ($totalSeekTimeNon0[$x]+5000*$missedCount[$x])/($correctCountNon0[$x]+$missedCount[$x]);
    }
    else{
      $avgSeekTimeNon0 = 5000;
    }
    print($avgSeekTimeCorrect.",".$avgSeekTimeNon0.",".$missedCount[$x].",".$correctCount[$x].",".$correctCountNon0[$x].",");
  }
}
###############################################################
sub calculateDistance{
  #picks are in a 4x4 grid with 1,2,3,4 in the top row
  #distance between each bag is 30 horizontal and 30 vertical
  #When given two bags, need to calculate the number of
  #horizontal grid moves and the number of vertical grid moves
  #then multiply by 30
  #Then find the direct line distance.  

  #first calculate row,col for a point1 and point2

  my $pt1 = @_[0]-1;
  my $pt2 = @_[1]-1;
  my $row1 = POSIX::floor($pt1/4);
  my $col1 = $pt1%4;

  my $row2 = POSIX::floor($pt2/4);
  my $col2 = $pt2%4;
  my $rowChange = $row1-$row2;
  if ($rowChange < 0) {
    $rowChange *=-1;
  }
  my $colChange = $col1-$col2;
  if ($colChange < 0) {
    $colChange *=-1;
  }
  my $distance = sqrt(($colChange*30)*($colChange*30)+($rowChange*30)*($rowChange*30));  

#  print ("Point1: $pt1-$row1,$col1\n");
#  print ("Point2: $pt2-$row2,$col2\n");
#  print ("$distance\n\n");
  return $distance;
  
}
###############################################################
sub getSearchTimes(){
  #times between PlaceNext and OnTarget or BagMissed
  #also need to look for control type switching
#  print ("ControlType: $ctrl[$ctrlIndex]\n");
  my $bagIndex = 0;
  my $bagLocation = -1;
  my $oldBagLocation = -1;
  $ctrlIndex = 0;
  $timeToSearch[$ctrl[$ctrlIndex]-1][$bagIndex]=0;
  $distanceToSearch[$ctrl[$ctrlIndex]-1][$bagIndex]=0;
  

  $handledHouse = true;
  open (MYFILE, $filename);
  while (<MYFILE>) {
    chomp;
    if (index($_,"RoundOver") > 1){
      $time = getMillisFromLine($_);
    }
    elsif (index($_,"BagTouched") > 1){
      $startTime = $time;
      $time = getMillisFromLine($_);
      $oldBagLocation = $bagLocation;
      $bagLocation = getBagIndexFromLine($_);
      if ($bagIndex > 0) {
         my $distance = calculateDistance($oldBagLocation,$bagLocation);
         $distanceToSearch[$ctrl[$ctrlIndex]-1][$bagIndex]=$distance;
      }
      my $diff = $time-$startTime;
      $timeToSearch[$ctrl[$ctrlIndex]-1][$bagIndex]=$diff;
      $bagIndex++;
    }
    elsif (index($_,"activeControl") > 1){
      $ctrlIndex++;
      $bagIndex = 0;
    }
  }
  close (MYFILE);
  for ($x = 0; $x < 3; $x ++ )
  { 
    my $total = 0;
    my $speedTotal = 0;
    for ($y = 0; $y < 5; $y++)
    {
      $total += $timeToSearch[$x][$y];
      print($timeToSearch[$x][$y].",");
      if ($y>0){
        print($distanceToSearch[$x][$y].",");
        print(($distanceToSearch[$x][$y]/$timeToSearch[$x][$y]).",");
        $speedTotal += $distanceToSearch[$x][$y]/$timeToSearch[$x][$y];
      }
    }
    print (($total/5).",");
    print (($speedTotal/4).",");
  }
}
###############################################################

getControlSequence();
getSeekTimes();    #how long to make the truck find the target
getSearchTimes();  #how long to choose a correct bag in the bonus

print("\n");
