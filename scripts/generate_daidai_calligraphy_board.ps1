param(
    [string]$OutputPath = "D:\personal\CountdownCalendar\packages\assets\design\logo-candidates\countdown-logo-v21-daidai-diagonal-real-fonts.png",
    [ValidateSet("Diagonal", "Horizontal", "HorizontalDiagonal")]
    [string]$Layout = "Diagonal"
)

Add-Type -AssemblyName System.Drawing

$canvasSize = 1600
$outerMargin = 32
$gutter = 24
$tileSize = [int](($canvasSize - 2 * $outerMargin - $gutter) / 2)

$bitmap = New-Object System.Drawing.Bitmap($canvasSize, $canvasSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::White)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

$black = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
$border = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(235, 235, 235), 2)
$format = [System.Drawing.StringFormat]::GenericTypographic
$format.FormatFlags = $format.FormatFlags -bor [System.Drawing.StringFormatFlags]::NoClip
$waitCharacter = [string][char]0x5F85
$arriveCharacter = [string][char]0x5230

function New-RoundedRectPath {
    param([float]$X, [float]$Y, [float]$Width, [float]$Height, [float]$Radius)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $Radius * 2
    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-Character {
    param(
        [string]$Character,
        [string]$FontFamily,
        [float]$Size,
        [float]$X,
        [float]$Y,
        [float]$Rotation = 0
    )
    $font = New-Object System.Drawing.Font($FontFamily, $Size, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $state = $graphics.Save()
    $graphics.TranslateTransform($X, $Y)
    $graphics.RotateTransform($Rotation)
    $graphics.DrawString($Character, $font, $black, 0, 0, $format)
    $graphics.Restore($state)
    $font.Dispose()
}

$diagonalVariants = @(
    @{ Font = "STXingkai"; WaitSize = 360; ArriveSize = 370; WaitX = 70; WaitY = 44; WaitR = -5; ArriveX = 355; ArriveY = 356; ArriveR = 7 },
    @{ Font = "FZShuTi"; WaitSize = 350; ArriveSize = 365; WaitX = 64; WaitY = 58; WaitR = -8; ArriveX = 350; ArriveY = 350; ArriveR = 5 },
    @{ Font = "STKaiti"; WaitSize = 340; ArriveSize = 355; WaitX = 74; WaitY = 54; WaitR = -7; ArriveX = 356; ArriveY = 358; ArriveR = 7 },
    @{ Font = "STXingkai"; WaitSize = 365; ArriveSize = 375; WaitX = 58; WaitY = 42; WaitR = -8; ArriveX = 330; ArriveY = 315; ArriveR = 8 }
)

$horizontalVariants = @(
    @{ Font = "STXingkai"; WaitSize = 330; ArriveSize = 340; WaitX = 42; WaitY = 190; WaitR = -4; ArriveX = 370; ArriveY = 184; ArriveR = 3 },
    @{ Font = "FZShuTi"; WaitSize = 315; ArriveSize = 325; WaitX = 52; WaitY = 196; WaitR = -5; ArriveX = 372; ArriveY = 187; ArriveR = 3 },
    @{ Font = "STKaiti"; WaitSize = 305; ArriveSize = 315; WaitX = 56; WaitY = 202; WaitR = -3; ArriveX = 376; ArriveY = 194; ArriveR = 2 },
    @{ Font = "STXingkai"; WaitSize = 350; ArriveSize = 360; WaitX = 28; WaitY = 176; WaitR = -6; ArriveX = 358; ArriveY = 166; ArriveR = 4 }
)

$horizontalDiagonalVariants = @(
    @{ Font = "STXingkai"; WaitSize = 335; ArriveSize = 345; WaitX = 38; WaitY = 92; WaitR = -5; ArriveX = 374; ArriveY = 272; ArriveR = 4 },
    @{ Font = "FZShuTi"; WaitSize = 320; ArriveSize = 330; WaitX = 50; WaitY = 108; WaitR = -6; ArriveX = 378; ArriveY = 266; ArriveR = 4 },
    @{ Font = "STXingkai"; WaitSize = 320; ArriveSize = 330; WaitX = 50; WaitY = 76; WaitR = -4; ArriveX = 382; ArriveY = 292; ArriveR = 5 },
    @{ Font = "STXingkai"; WaitSize = 355; ArriveSize = 365; WaitX = 22; WaitY = 92; WaitR = -7; ArriveX = 356; ArriveY = 250; ArriveR = 6 }
)

$variants = switch ($Layout) {
    "Horizontal" { $horizontalVariants }
    "HorizontalDiagonal" { $horizontalDiagonalVariants }
    default { $diagonalVariants }
}

for ($i = 0; $i -lt $variants.Count; $i++) {
    $row = [math]::Floor($i / 2)
    $col = $i % 2
    $x = $outerMargin + $col * ($tileSize + $gutter)
    $y = $outerMargin + $row * ($tileSize + $gutter)
    $path = New-RoundedRectPath -X $x -Y $y -Width $tileSize -Height $tileSize -Radius 92
    $graphics.DrawPath($border, $path)

    $v = $variants[$i]
    Draw-Character -Character $waitCharacter -FontFamily $v.Font -Size $v.WaitSize -X ($x + $v.WaitX) -Y ($y + $v.WaitY) -Rotation $v.WaitR
    Draw-Character -Character $arriveCharacter -FontFamily $v.Font -Size $v.ArriveSize -X ($x + $v.ArriveX) -Y ($y + $v.ArriveY) -Rotation $v.ArriveR
    $path.Dispose()
}

$outputDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$format.Dispose()
$border.Dispose()
$black.Dispose()
$graphics.Dispose()
$bitmap.Dispose()

Write-Output $OutputPath
