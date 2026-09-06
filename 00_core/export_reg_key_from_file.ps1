param(
  [parameter(mandatory=$true)][string]$regfile,
  [parameter(mandatory=$true)][string]$backupfile
)
$erroractionpreference = 'stop'
$lines = get-content -literalpath $regfile -erroraction stop
$section = $lines | where-object { $_ -match '^\s*\[(.+)\]\s*$' } | select-object -first 1
if (-not $section) { throw "reg sem secao valida: $regfile" }
$key = $matches[1]
if ($key -match '^hkey_current_user\\') { $root='hkcu'; $sub=$key.substring(18) }
elseif ($key -match '^hkey_local_machine\\') { $root='hklm'; $sub=$key.substring(19) }
elseif ($key -match '^hkey_classes_root\\') { $root='hkcr'; $sub=$key.substring(18) }
else { throw "hive nao suportado para backup automatico: $key" }
$regpath = "$root\$sub"
$backupdir = split-path -parent $backupfile
new-item -itemtype directory -path $backupdir -force | out-null
& reg.exe export "$regpath" "$backupfile" /y | out-file -filepath $backupfile'.log' -encoding utf8
if ($lastexitcode -ne 0) {
  "windows registry editor version 5.00`r`n" | set-content -literalpath $backupfile -encoding ascii
  "empty_key=1`r`nkey=$key" | set-content -literalpath ($backupfile+'.meta') -encoding ascii
}
