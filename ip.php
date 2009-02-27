<?php
// ----------------------------------------------------------------------------
// Script Name: ip.php
// Creation Date: 25.02.2009
// Last Modified: 28.02.2009
// Copyright (c)2009 Swed
// Purpose: Administrated client's IP data updater
// ----------------------------------------------------------------------------
error_reporting("E_ALL & ~E_NOTICE & ~E_STRICT");

$selfname = basename($_SERVER["PHP_SELF"],".php");
$workdir  = dirname($_SERVER["DOCUMENT_ROOT"]."/../data/file");
$logdir   = dirname($_SERVER["DOCUMENT_ROOT"]."/../log/file");
$user     =  $_SERVER[PHP_AUTH_USER];// $_POST[user]
$pass     =  $_SERVER[PHP_AUTH_PW];
$client   =  $_REQUEST[client];
$ip       =  $_REQUEST[ip];
$subj     =  "IP:";
$data     =  $_REQUEST[data];
$datafile = "$workdir/$client.ip";
$lastsendfile = "$workdir/$client.lst";
$email = "";   //  

function SendMessage ($to,$subject,$mess,$from="",$headers="",$log="") {
   if (!$from) $from = basename($_SERVER["PHP_SELF"])."@".$_SERVER[HTTP_HOST];
//print "FROM = $from";
   if (!preg_match("/@/",$to)) 
    $to = $email;
    ($send=true and @mail($to, $subject, $mess,
     "From: $from\r\n".
     "Reply-To: $from\r\n".
//     "Return-path: $from\r\n".
     "X-Mailer: PHP/" . phpversion()."\r\n".
      $headers) 
     ) or ( $send = false );
     if ($log or !$send ) {
      if (!$send) $log=0;
      error_log(strtr($php_errormsg." Subject: \"$subject\". Message: \"$mess\"",
      array_flip(get_html_translation_table(HTML_ENTITIES))),$log?3:0,$log);
     }
   return $send;
     
}
function SaveTextToFile($datafile,$text,$type="w"){
   if (!$handle = fopen($datafile, $type)) {
      SendMessage($email,"$subj Error","Cannot open file \"$datafile\" for write text \"".$text."\"");
   }
   if (!fwrite($handle, $text)) {
      SendMessage($email,"$subj Error","Cannot write text \"".$text."\" to file \"$datafile\"");
   }
   fclose($handle);
}


if ($client) {
// check received info 
 $oldip=@file_get_contents($datafile);
 if ($_REQUEST[showonly]) {
   echo $oldip;
   exit();
 }
}

echo $_SERVER[REMOTE_ADDR];


if (!realpath($logdir))  mkdir($logdir) or SendMessage($email,$subj." Error create dir",$php_errormsg."\n$logdir");
if (!realpath($workdir)) mkdir($workdir) or SendMessage($email,$subj." Error create dir",$php_errormsg."\n$workdir");

if ($client) SaveTextToFile($datafile,$_SERVER[REMOTE_ADDR]);   

if (!$oldip or $oldip != $_SERVER[REMOTE_ADDR] ) {
 $mess = $_SERVER[REMOTE_ADDR]." ".date('j.m.y h:i:s')." ".$_SERVER["REMOTE_HOST"]." $user:$pass@$client:$ip Old Ip = $oldip.".($data?" Data = $data":"");
 $send = SendMessage($email,"$subj $client",$mess,"","","$logdir/".$_SERVER["SERVER_NAME"]."_$selfname");
 if ($client) SaveTextToFile($lastsendfile,date('j.m.y h:i:s')." ".($send?"Success":"Error")." while sending mess $mess");
}


?>