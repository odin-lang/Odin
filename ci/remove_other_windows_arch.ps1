param(
	[Parameter(Mandatory = $true)]
	[ValidateSet("amd64", "arm64")]
	[string]$Architecture,

	[Parameter(Mandatory = $true)]
	[string]$Root
)

$root_path = (Resolve-Path -LiteralPath $Root).Path
$root_prefix = $root_path + [IO.Path]::DirectorySeparatorChar

function Remove-DirectoryInsideRoot {
	param([string]$Path)

	if (!(Test-Path -LiteralPath $Path)) {
		return
	}

	$full_path = [IO.Path]::GetFullPath($Path)
	if (!($full_path + [IO.Path]::DirectorySeparatorChar).StartsWith($root_prefix, [StringComparison]::OrdinalIgnoreCase)) {
		throw "Refusing to remove directory outside artifact root: $full_path"
	}

	Remove-Item -LiteralPath $full_path -Recurse -Force
}

$other_arch = if ($Architecture -eq "amd64") { "arm64" } else { "amd64" }
$vendor_path = Join-Path $root_path "vendor"

Get-ChildItem -LiteralPath $vendor_path -Directory -Recurse |
	Where-Object { $_.Name -eq $other_arch } |
	Sort-Object FullName -Descending |
	ForEach-Object { Remove-DirectoryInsideRoot $_.FullName }

$other_llvm_arch = if ($Architecture -eq "amd64") { "arm64" } else { "x64" }
Remove-DirectoryInsideRoot (Join-Path $root_path "bin\llvm\windows\$other_llvm_arch")

$other_wgpu_arch = if ($Architecture -eq "amd64") { "aarch64" } else { "x86_64" }
Remove-DirectoryInsideRoot (Join-Path $vendor_path "wgpu\lib\wgpu-windows-$other_wgpu_arch-msvc-release")
