$erroractionpreference='stop'
$os=get-ciminstance win32_operatingsystem
$cs=get-ciminstance win32_computersystem
$cpu=get-ciminstance win32_processor | select-object -first 1
$gpus=@(get-ciminstance win32_videocontroller)
$batt=@(get-ciminstance win32_battery)
$ramgb=[math]::round($cs.totalphysicalmemory/1gb,1)
$logical=[int]$cpu.numberoflogicalprocessors
$cores=[int]$cpu.numberofcores
$desktop=($batt.count -eq 0)
$gpunames=($gpus.name -join '; ')
$gpuvendor='other'
if($gpunames -match 'nvidia'){$gpuvendor='nvidia'} elseif($gpunames -match 'amd|radeon'){$gpuvendor='amd'} elseif($gpunames -match 'intel'){$gpuvendor='intel'}
$class='balanced'
if($ramgb -le 8 -or $logical -le 4){$class='low_resource'}
elseif($ramgb -ge 16 -and $logical -ge 8){$class='high_headroom'}
[pscustomobject]@{os=$os.caption;build=$os.buildnumber;ramgb=$ramgb;cores=$cores;logical=$logical;desktop=$desktop;gpuvendor=$gpuvendor;gpus=$gpunames;profileclass=$class;safedefault='true'} | convertto-json -compress
