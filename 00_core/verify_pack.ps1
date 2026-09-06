$erroractionpreference='stop'
$root=(resolve-path (join-path $psscriptroot '..')).path
$reportdir=join-path $root 'data\reports'; new-item -itemtype directory -force -path $reportdir | out-null
$report=join-path $reportdir 'pack_validation.txt'
$errors=[system.collections.generic.list[string]]::new()
$allfiles=get-childitem -literalpath $root -recurse -file
foreach($f in $allfiles | where-object {$_.extension -in '.bat','.cmd'}){
  $lines=get-content -literalpath $f.fullname
  foreach($line in $lines){
    foreach($m in [regex]::matches($line,'(?i)\b(?:call|start\s+"[^"]*"|explorer)\s+"([^"]+)"')){
      $ref=$m.groups[1].value
      if($ref -match '^(?:https?://|[a-za-z]:\\|\\\\|%|!|"|%%|%~dp0)'){continue}
      $candidate=join-path $f.directoryname $ref.replace('/','\\')
      if(-not(test-path -literalpath $candidate)){$errors.add("missing|$($f.fullname.substring($root.length+1))|$ref")}
    }
  }
}
foreach($f in $allfiles|where-object {$_.extension -eq '.reg'}){
  $first=((get-content -literalpath $f.fullname|where-object {$_ -ne ''}|select-object -first 1)).trimstart([char]0xfeff)
  if($first -notmatch '^windows registry editor version 5\.00$'){$errors.add("bad_reg_header|$($f.fullname.substring($root.length+1))")}
  if((get-content -raw -literalpath $f.fullname) -match 'yourgame'){$errors.add("placeholder_reg|$($f.fullname.substring($root.length+1))")}
}
$start=get-content -raw -literalpath (join-path $root 'start_here.bat')
foreach($line in ($start -split "`r?`n")){ if($line -match '(?i)^\s*if\s+"%c%"=="[^"]+"\s+.+\s+&\s+goto\s+menu\s*$' -and $line -notmatch '\(.*\)'){$errors.add('menu_if_chain_without_parens')} }
$common=get-content -raw -literalpath (join-path $root '00_core\common.bat')
if($common -match '(?im)^\s*setlocal\b'){$errors.add('common_setlocal_breaks_caller_scope')}
if($common -notmatch 'nb_state='){$errors.add('common_nb_state_missing')}
$parking=get-content -raw -literalpath (join-path $root '12_cpu_advanced\01_core_parking_off.bat')
if($parking -match '(?im)cpmincores\s+100\s*\r?\n[^\r\n]*powercfg\s+/setdcvalueindex'){$errors.add('core_parking_dc_change_in_safe_advanced_module')}
$snap=get-content -raw -literalpath (join-path $root '10_backup_rollback\09_snapshot_all.bat')
if($snap -notmatch 'set "rc=0"'){$errors.add('snapshot_all_no_rc')}
if($snap -notmatch 'endlocal & exit /b %rc%'){$errors.add('snapshot_all_does_not_propagate_rc')}
$compare=get-content -raw -literalpath (join-path $root '19_benchmark_automation\03_compare_runs.ps1')
if($compare -notmatch 'ceiling\(\$fps\.count\*0\.01\)'){$errors.add('benchmark_1pct_method_missing')}
if($compare -notmatch 'p99frametimems'){$errors.add('benchmark_p99_missing')}
$manifestpath=join-path $root 'manifest.json'
if(test-path $manifestpath){
  $manifest=get-content -raw -literalpath $manifestpath|convertfrom-json
  $listed=@($manifest.files)
  $actual=@($allfiles|where-object {$_.name -notin @('manifest.json','validation_report.txt','pack_validation.txt')}|foreach-object {$_.fullname.substring($root.length+1).replace('\\','/')})
  if([int]$manifest.file_count -ne $listed.count){$errors.add("manifest_count_field|declared=$($manifest.file_count)|listed=$($listed.count)")}
  if($listed.count -ne $actual.count){$errors.add("manifest_count_actual|listed=$($listed.count)|actual=$($actual.count)")}
  $bypath=@{}; foreach($e in $listed){$bypath[$e.path]=$e}
  foreach($rp in $actual){if(-not $bypath.containskey($rp)){$errors.add("manifest_missing|$rp")}}
  foreach($e in $listed){$fp=join-path $root ($e.path.replace('/','\\')); if(-not(test-path -literalpath $fp)){$errors.add("manifest_path_missing|$($e.path)");continue}; $sha=(get-filehash -literalpath $fp -algorithm sha256).hash.tolowerinvariant(); if($sha -ne $e.sha256.tolowerinvariant()){$errors.add("manifest_hash|$($e.path)")}}
}
$body=@("naveboost turbo pro 7.3 validation","date=$(get-date -format o)","errors=$($errors.count)")+$(if($errors.count){$errors}else{@('ok')})
$body|set-content -literalpath $report -encoding utf8;$body|write-output
if($errors.count){exit 1}else{exit 0}
