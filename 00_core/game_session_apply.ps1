param(
  [parameter(mandatory=$true)][string]$processname,
  [validateset('balanced','competitive','lowend','quality','latency','fps60','fps120')][string]$mode='balanced'
)
$erroractionpreference='stop'
$name = [io.path]::getfilenamewithoutextension($processname)
$procs = @(get-process -name $name -erroraction silentlycontinue)
if (-not $procs) { write-host "processo '$name' nao encontrado. abra o jogo primeiro."; exit 2 }
$map = @{
  balanced='abovenormal'; competitive='abovenormal'; lowend='abovenormal'; quality='abovenormal'; latency='abovenormal'; fps60='abovenormal'; fps120='abovenormal'
}
$changed=0; $failed=0
foreach($p in $procs){
  try {
    $old=$p.priorityclass
    $p.priorityclass=$map[$mode]
    try { $p.priorityboostenabled=$true } catch {}
    write-host ("pid {0}: {1} -> {2} | mode={3}" -f $p.id,$old,$p.priorityclass,$mode)
    $changed++
  } catch {
    write-host ("pid {0}: falha: {1}" -f $p.id,$_.exception.message)
    $failed++
  }
}
write-host "aplicados=$changed falhas=$failed"
if($changed -eq 0){ exit 3 }
if($failed -gt 0){ exit 4 }
exit 0
