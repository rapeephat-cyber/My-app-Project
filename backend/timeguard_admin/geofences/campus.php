<?php
require_once __DIR__.'/../includes/bootstrap.php';
require_once __DIR__.'/../includes/repository.php';
require_once __DIR__.'/../includes/geofence_layers.php';
permit('geofences.write');check_csrf();$area=input('area_id');
if($area!==''&&!q("SELECT area_id FROM geofence_areas WHERE area_id=? AND status='active'",[$area])->fetch())abort_page(422,'กรุณาเลือกพื้นที่ที่ใช้งานอยู่');
$lock=fopen(__DIR__.'/../config/campus-layer.lock','c');
if(!$lock||!flock($lock,LOCK_EX))throw new RuntimeException('Cannot lock campus layer configuration');
$file=campus_layer_file();$old=is_file($file)?file_get_contents($file):null;$temp=null;$written=false;
try {
    db()->beginTransaction();$GLOBALS['web_transaction']=true;
    audit('update','map_layers',$area?:'campus',['campus_area_id']);
    $temp=tempnam(dirname($file),'campus-');
    if($temp===false||file_put_contents($temp,json_encode(['area_id'=>$area],JSON_UNESCAPED_UNICODE),LOCK_EX)===false||!rename($temp,$file))throw new RuntimeException('Cannot save campus layer configuration');
    $written=true;db()->commit();
}catch(Throwable $ex){
    if(db()->inTransaction())db()->rollBack();
    if($written){if($old===null)unlink($file);else file_put_contents($file,$old,LOCK_EX);}
    if($temp&&is_file($temp))unlink($temp);throw $ex;
}finally{flock($lock,LOCK_UN);fclose($lock);}
flash('บันทึกชั้นขอบเขตมหาวิทยาลัยสำเร็จ');redirect('geofences/');
