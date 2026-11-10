# Installs the read-only WhatsApp bridge of the somente-leitura branch on a Windows computer.
#
#   git clone -b somente-leitura https://github.com/Chrysthofer/whatsapp-mcp.git $HOME\.whatsapp-mcp
#   powershell -ExecutionPolicy Bypass -File $HOME\.whatsapp-mcp\instalar.ps1 -Projeto C:\caminho\do\romanova
#
# Then open iniciar-ponte.cmd from Explorer and scan the QR code with the phone
# (WhatsApp > Linked devices). The session and the messages stay in
# whatsapp-bridge\store, which git ignores and which must never be pushed.
param(
    [string]$Projeto = "",          # folder where Claude Code registers the MCP server (local scope)
    [string]$Whisper = "",          # optional: whisper-cli.exe, for audio transcription
    [string]$Modelo = ""            # optional: the whisper.cpp model file
)
$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot

function Exige($nome, $dica) {
    if (-not (Get-Command $nome -ErrorAction SilentlyContinue)) { throw "missing $nome: $dica" }
}
Exige go    'install Go from https://go.dev/dl/'
Exige uv    'install uv from https://docs.astral.sh/uv/'
$cc = if (Get-Command clang -ErrorAction SilentlyContinue) { 'clang' } elseif (Get-Command gcc -ErrorAction SilentlyContinue) { 'gcc' } else { throw 'missing a C compiler (clang or gcc): go-sqlite3 needs cgo' }

Write-Host "== building the bridge with $cc"
Push-Location "$raiz\whatsapp-bridge"
try {
    $env:CGO_ENABLED = '1'; $env:CC = $cc
    go build -o whatsapp-bridge.exe .
    if ($LASTEXITCODE) { throw 'go build failed' }
    go test -run 'TestReadOnly|TestWebhooksOffByDefault' .
    if ($LASTEXITCODE) { throw 'the read-only tests failed: do not use this build' }
} finally { Pop-Location }

Write-Host '== preparing the MCP server'
uv --directory "$raiz\whatsapp-mcp-server" sync
if ($LASTEXITCODE) { throw 'uv sync failed' }

if ($Projeto) {
    Write-Host "== registering the MCP server in $Projeto (local scope)"
    $args_ = @('mcp', 'add', 'whatsapp', '-s', 'local')
    if ($Whisper) { $args_ += @('-e', "WHISPER_BINARY=$Whisper") }
    if ($Modelo)  { $args_ += @('-e', "WHISPER_MODEL=$Modelo", '-e', 'WHISPER_LANGUAGE=auto') }
    $args_ += @('--', 'uv', '--directory', "$raiz\whatsapp-mcp-server", 'run', 'main.py')
    Push-Location $Projeto
    try { claude @args_ } finally { Pop-Location }
}

Write-Host ''
Write-Host 'Done. Next: open iniciar-ponte.cmd from Explorer and scan the QR code.'
Write-Host 'The device shows on the phone as "Claude (somente leitura)".'
