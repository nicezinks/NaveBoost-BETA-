param([parameter(mandatory=$true)][string]$baseline,[parameter(mandatory=$true)][string]$post)
$erroractionpreference='stop'
function get-column($rows,[string[]]$names){
  if(-not $rows -or $rows.count -eq 0){return $null}
  $props=$rows[0].psobject.properties.name
  foreach($n in $names){$hit=$props | where-object { $_ -ieq $n } | select-object -first 1; if($hit){return $hit}}
  return $null
}
function read-metrics($path){
  $rows=@(import-csv -literalpath $path)
  if($rows.count -lt 100){ throw "poucos registros em $path (minimo 100)" }
  $col=get-column $rows @('frametime','frametimems','msbetweenpresents','msbetweenpresents','msbetweendisplaychange')
  if(-not $col){ throw "coluna de frametime nao encontrada em $path" }
  $ms=@()
  foreach($r in $rows){
    $v=0.0; $raw=[string]$r.$col
    if([double]::tryparse($raw,[globalization.numberstyles]::float,[globalization.cultureinfo]::invariantculture,[ref]$v) -and $v -gt 0 -and $v -lt 1000){$ms += $v}
  }
  if($ms.count -lt 100){throw "poucos frametimes validos em $path"}
  $fps=@($ms | foreach-object {1000.0/$_})
  $fpssorted=@($fps | sort-object)
  $mssorted=@($ms | sort-object)
  $onen=[math]::max(1,[int][math]::ceiling($fps.count*0.01))
  $zeroonen=[math]::max(1,[int][math]::ceiling($fps.count*0.001))
  $oneavg=[math]::round((($fpssorted | select-object -first $onen | measure-object -average).average),2)
  $zerooneavg=[math]::round((($fpssorted | select-object -first $zeroonen | measure-object -average).average),2)
  $p99msn=[math]::max(1,[int][math]::ceiling($ms.count*0.99))
  $p99ms=[math]::round($mssorted[$p99msn-1],2)
  [pscustomobject]@{
    avgfps=[math]::round((($fps|measure-object -average).average),2)
    low1=$oneavg
    low01=$zerooneavg
    p99frametimems=$p99ms
    maxframetimems=[math]::round((($ms|measure-object -maximum).maximum),2)
    frames=$fps.count
  }
}
function safepct([double]$a,[double]$b){if($a -eq 0){return 0};[math]::round((($b/$a)-1)*100,2)}
$b=read-metrics $baseline; $p=read-metrics $post
$results=@(
 [pscustomobject]@{metric='avgfps';baseline=$b.avgfps;post=$p.avgfps;delta=[math]::round($p.avgfps-$b.avgfps,2);percent=(safepct $b.avgfps $p.avgfps)},
 [pscustomobject]@{metric='1% low';baseline=$b.low1;post=$p.low1;delta=[math]::round($p.low1-$b.low1,2);percent=(safepct $b.low1 $p.low1)},
 [pscustomobject]@{metric='0.1% low';baseline=$b.low01;post=$p.low01;delta=[math]::round($p.low01-$b.low01,2);percent=(safepct $b.low01 $p.low01)},
 [pscustomobject]@{metric='p99 frametime ms';baseline=$b.p99frametimems;post=$p.p99frametimems;delta=[math]::round($p.p99frametimems-$b.p99frametimems,2);percent=(safepct $b.p99frametimems $p.p99frametimems)},
 [pscustomobject]@{metric='maxframetimems';baseline=$b.maxframetimems;post=$p.maxframetimems;delta=[math]::round($p.maxframetimems-$b.maxframetimems,2);percent=(safepct $b.maxframetimems $p.maxframetimems)}
)
$results | format-table -autosize | out-string | write-output
$avg=$results|? metric -eq 'avgfps'; $low=$results|? metric -eq '1% low'; $low01=$results|? metric -eq '0.1% low'; $p99=$results|? metric -eq 'p99 frametime ms'
if($avg.percent -ge 2 -and $low.percent -ge 1 -and $low01.percent -ge 1 -and $p99.delta -le 0.5){'decisao=keep'}
elseif($avg.percent -le -2 -or $low.percent -le -2 -or $low01.percent -le -2 -or $p99.delta -ge 2){'decisao=rollback_recommended'}
else{'decisao=retest'}
