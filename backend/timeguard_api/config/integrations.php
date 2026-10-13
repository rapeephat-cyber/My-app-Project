<?php
$c=['google_client_id'=>'764367490870-n17cmlp7q4mr42aco2ar1k81bpsuqfku.apps.googleusercontent.com','face_service_url'=>'http://127.0.0.1:8091','face_service_key'=>''];
if(is_file(__DIR__.'/integrations.local.php')){$c=array_replace($c,require __DIR__.'/integrations.local.php');}
foreach(array_keys($c) as $key){$v=getenv('TIMEGUARD_'.strtoupper($key));if($v!==false){$c[$key]=$v;}}
return $c;
