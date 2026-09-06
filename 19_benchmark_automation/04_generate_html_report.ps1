param([parameter(mandatory=$true)][string]$textreport,[parameter(mandatory=$true)][string]$output)
$erroractionpreference='stop'
$lines=get-content -literalpath $textreport | where-object {$_ -match '^@?\{' -or $_ -match '^metric'}
$html=@('<html><head><meta charset="utf-8"><title>naveboost benchmark</title><style>body{font-family:segoe ui,arial;margin:30px}table{border-collapse:collapse}td,th{border:1px solid #aaa;padding:8px}th{background:#eee}</style></head><body><h1>naveboost benchmark</h1><p>relatorio gerado localmente.</p><pre>')
$html += [system.web.httputility]::htmlencode(($lines -join "`n"));$html += '</pre></body></html>'
set-content -literalpath $output -value $html -encoding utf8
