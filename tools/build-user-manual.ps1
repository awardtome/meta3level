param(
  [Parameter(Mandatory = $true)][string]$MarkdownPath,
  [Parameter(Mandatory = $true)][string]$HtmlPath,
  [Parameter(Mandatory = $true)][string]$DocxPath,
  [Parameter(Mandatory = $true)][string]$PdfPath,
  [ValidateSet("zh-CN", "en")][string]$Language = "zh-CN"
)

$ErrorActionPreference = "Stop"

function WordColor([int]$Red, [int]$Green, [int]$Blue) {
  return $Red + (256 * $Green) + (65536 * $Blue)
}

function SetFont([object]$Font, [string]$Latin, [string]$EastAsia, [double]$Size) {
  $Font.Name = $Latin
  try { $Font.NameFarEast = $EastAsia } catch { }
  $Font.Size = $Size
}

function SetStyleFont([object]$Style, [string]$Latin, [string]$EastAsia,
                      [double]$Size, [bool]$Bold, [int]$Color) {
  SetFont $Style.Font $Latin $EastAsia $Size
  $Style.Font.Bold = if ($Bold) { -1 } else { 0 }
  $Style.Font.Color = $Color
}

$markdown = (Resolve-Path -LiteralPath $MarkdownPath).Path
$html = (Resolve-Path -LiteralPath $HtmlPath).Path
$docx = [System.IO.Path]::GetFullPath($DocxPath)
$pdf = [System.IO.Path]::GetFullPath($PdfPath)
[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($docx)) | Out-Null
[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($pdf)) | Out-Null

$firstLine = Get-Content -LiteralPath $markdown -Encoding UTF8 -TotalCount 1
$title = ($firstLine -replace '^#[ ]+', '').Trim()
if (-not $title) { $title = "meta3level 0.6.2 Complete User Manual" }
$isEnglish = $Language -eq "en"
$tocTitle = if ($isEnglish) { "Table of Contents" } else { "目录" }
$headerText = if ($isEnglish) {
  "meta3level 0.6.2  |  Complete English User Manual"
} else {
  "meta3level 0.6.2  |  完整使用说明书"
}

$word = $null
$document = $null
try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0
  $document = $word.Documents.Add()

  # Letter portrait with one-inch margins.
  $document.PageSetup.PageWidth = 612
  $document.PageSetup.PageHeight = 792
  $document.PageSetup.TopMargin = 72
  $document.PageSetup.BottomMargin = 72
  $document.PageSetup.LeftMargin = 72
  $document.PageSetup.RightMargin = 72
  $document.PageSetup.HeaderDistance = 36
  $document.PageSetup.FooterDistance = 36

  $normal = $document.Styles.Item(-1)
  SetStyleFont $normal "Calibri" "Microsoft YaHei" 11 $false (WordColor 32 38 46)
  $normal.ParagraphFormat.SpaceAfter = 6
  $normal.ParagraphFormat.LineSpacingRule = 5
  $normal.ParagraphFormat.LineSpacing = 13.75

  $heading1 = $document.Styles.Item(-2)
  SetStyleFont $heading1 "Calibri" "Microsoft YaHei" 16 $true (WordColor 31 78 121)
  $heading1.ParagraphFormat.SpaceBefore = 18
  $heading1.ParagraphFormat.SpaceAfter = 10
  $heading1.ParagraphFormat.KeepWithNext = -1
  $heading1.ParagraphFormat.OutlineLevel = 1

  $heading2 = $document.Styles.Item(-3)
  SetStyleFont $heading2 "Calibri" "Microsoft YaHei" 13 $true (WordColor 47 95 133)
  $heading2.ParagraphFormat.SpaceBefore = 14
  $heading2.ParagraphFormat.SpaceAfter = 7
  $heading2.ParagraphFormat.KeepWithNext = -1
  $heading2.ParagraphFormat.OutlineLevel = 2

  $heading3 = $document.Styles.Item(-4)
  SetStyleFont $heading3 "Calibri" "Microsoft YaHei" 12 $true (WordColor 51 78 104)
  $heading3.ParagraphFormat.SpaceBefore = 10
  $heading3.ParagraphFormat.SpaceAfter = 5
  $heading3.ParagraphFormat.KeepWithNext = -1
  $heading3.ParagraphFormat.OutlineLevel = 3

  $titleStyle = $document.Styles.Item(-63)
  SetStyleFont $titleStyle "Calibri" "Microsoft YaHei" 28 $true (WordColor 31 78 121)
  $titleStyle.ParagraphFormat.Alignment = 1
  $titleStyle.ParagraphFormat.SpaceAfter = 16

  $codeStyle = $document.Styles.Add("MetaCode", 1)
  SetStyleFont $codeStyle "Consolas" "Microsoft YaHei" 8.5 $false (WordColor 32 38 46)
  $codeStyle.ParagraphFormat.LeftIndent = 8
  $codeStyle.ParagraphFormat.RightIndent = 8
  $codeStyle.ParagraphFormat.SpaceBefore = 4
  $codeStyle.ParagraphFormat.SpaceAfter = 6
  $codeStyle.ParagraphFormat.LineSpacingRule = 0
  $codeStyle.ParagraphFormat.KeepTogether = 0
  $codeStyle.ParagraphFormat.KeepWithNext = 0
  $codeStyle.ParagraphFormat.Shading.BackgroundPatternColor = WordColor 244 246 248

  $selection = $word.Selection
  $selection.Style = $titleStyle
  $selection.ParagraphFormat.SpaceBefore = 150
  $selection.TypeText($title)
  $selection.TypeParagraph()

  SetFont $selection.Font "Calibri" "Microsoft YaHei" 12
  $selection.Font.Bold = 0
  $selection.Font.Color = WordColor 80 96 112
  $selection.ParagraphFormat.Alignment = 1
  $selection.TypeText("THREE-LEVEL AND SINGLE-LEVEL META-ANALYSIS IN R")
  $selection.TypeParagraph()
  $selection.TypeParagraph()
  SetFont $selection.Font "Consolas" "Microsoft YaHei" 10
  $selection.TypeText("r  |  d  |  g  |  OR  |  custom yi/vi")
  $selection.TypeParagraph()
  $selection.TypeParagraph()
  SetFont $selection.Font "Calibri" "Microsoft YaHei" 10
  $selection.TypeText("Version 0.6.2  |  2026-08-13")
  $selection.InsertBreak(7)

  $selection.Style = $heading1
  $selection.TypeText($tocTitle)
  $selection.TypeParagraph()
  $tocRange = $selection.Range
  $toc = $document.TablesOfContents.Add($tocRange, $true, 1, 3)
  $selection.SetRange($toc.Range.End, $toc.Range.End)
  $selection.TypeParagraph()
  $selection.InsertBreak(7)

  $selection.InsertFile($html)

  # Normalize imported HTML paragraphs while retaining real list formatting.
  foreach ($paragraph in @($document.Paragraphs)) {
    $styleName = ""
    try { $styleName = [string]$paragraph.Style.NameLocal } catch { }
    if ($styleName -match 'Preformatted|HTML.*Pre|预设格式|预格式') {
      $paragraph.Style = $codeStyle
    } elseif ($styleName -match 'Normal \(Web\)|正文 \(Web\)|普通.*Web') {
      $paragraph.Style = $normal
    }
  }

  foreach ($table in @($document.Tables)) {
    $table.AllowAutoFit = -1
    $table.AutoFitBehavior(2)
    $table.LeftPadding = 6
    $table.RightPadding = 6
    $table.TopPadding = 4
    $table.BottomPadding = 4
    $table.Rows.AllowBreakAcrossPages = 0
    if ($table.Rows.Count -ge 1) {
      $table.Rows.Item(1).HeadingFormat = -1
      $table.Rows.Item(1).Range.Font.Bold = -1
      $table.Rows.Item(1).Shading.BackgroundPatternColor = WordColor 232 238 245
    }
    SetFont $table.Range.Font "Calibri" "Microsoft YaHei" 9.5
    $table.Range.ParagraphFormat.SpaceAfter = 2
  }

  foreach ($section in @($document.Sections)) {
    $section.PageSetup.DifferentFirstPageHeaderFooter = -1
    $header = $section.Headers.Item(1).Range
    $header.Text = $headerText
    SetFont $header.Font "Calibri" "Microsoft YaHei" 8.5
    $header.Font.Color = WordColor 112 128 144
    $header.ParagraphFormat.Alignment = 0

    $footer = $section.Footers.Item(1).Range
    $footer.Text = ""
    $footer.ParagraphFormat.Alignment = 1
    SetFont $footer.Font "Calibri" "Microsoft YaHei" 8.5
    $footer.Font.Color = WordColor 112 128 144
    $section.Footers.Item(1).PageNumbers.Add(1, $false) | Out-Null
    $section.Headers.Item(2).Range.Text = ""
    $section.Footers.Item(2).Range.Text = ""
  }

  $document.TablesOfContents.Item(1).Update()
  $document.Fields.Update() | Out-Null
  $document.Repaginate()
  $document.SaveAs2($docx, 16)
  $document.ExportAsFixedFormat($pdf, 17)
  $pages = $document.ComputeStatistics(2)
  Write-Output ("DOCX={0}" -f $docx)
  Write-Output ("PDF={0}" -f $pdf)
  Write-Output ("PAGES={0}" -f $pages)
  Write-Output ("TABLES={0}" -f $document.Tables.Count)
  Write-Output ("TOC={0}" -f $document.TablesOfContents.Count)
} finally {
  if ($null -ne $document) { $document.Close(0) }
  if ($null -ne $word) { $word.Quit() }
  if ($null -ne $document) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($document) }
  if ($null -ne $word) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($word) }
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}
