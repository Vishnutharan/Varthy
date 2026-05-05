$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$DesktopDir = if ($env:VAR_DESKTOP_DIR) { $env:VAR_DESKTOP_DIR } else { 'C:\Users\karun\OneDrive\Desktop\Var' }
$WorkspaceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DocxPath = Join-Path $DesktopDir 'result.docx'
$SummaryPath = Join-Path $DesktopDir 'analysis_summary.json'
$BackupPath = Join-Path $DesktopDir 'result.original_backup.docx'
$TempRoot = Join-Path $WorkspaceDir 'tmp'
$TempDir = Join-Path $TempRoot 'docx_work'
$TempDocx = Join-Path $TempRoot 'result.fixed.docx'
$WNs = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

if (-not (Test-Path -LiteralPath $DocxPath)) { throw "Missing DOCX: $DocxPath" }
if (-not (Test-Path -LiteralPath $SummaryPath)) { throw "Missing analysis summary: $SummaryPath. Run node clean_excel.js first." }
if (-not (Test-Path -LiteralPath $BackupPath)) {
  Copy-Item -LiteralPath $DocxPath -Destination $BackupPath
}

if (Test-Path -LiteralPath $TempDir) { Remove-Item -LiteralPath $TempDir -Recurse -Force }
if (Test-Path -LiteralPath $TempDocx) { Remove-Item -LiteralPath $TempDocx -Force }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

[System.IO.Compression.ZipFile]::ExtractToDirectory($DocxPath, $TempDir)
$DocumentXmlPath = Join-Path $TempDir 'word\document.xml'
$RelationshipsPath = Join-Path $TempDir 'word\_rels\document.xml.rels'
$ContentTypesPath = Join-Path $TempDir '[Content_Types].xml'
$StudyMapPath = Join-Path $WorkspaceDir 'assets\study_area_map.jpeg'
[xml]$Doc = Get-Content -LiteralPath $DocumentXmlPath -Raw
$Ns = New-Object System.Xml.XmlNamespaceManager($Doc.NameTable)
$Ns.AddNamespace('w', $WNs)
$Ns.AddNamespace('r', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
$Summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
if (-not (Test-Path -LiteralPath $StudyMapPath)) { throw "Missing study area map asset: $StudyMapPath" }

function Get-NodeText($Node) {
  (($Node.SelectNodes('.//w:t', $Ns) | ForEach-Object { $_.'#text' }) -join '') -replace '\s+', ' '
}

function Set-ParagraphText($Paragraph, [string]$Text) {
  $children = @($Paragraph.ChildNodes)
  foreach ($child in $children) {
    if ($child.LocalName -ne 'pPr') {
      [void]$Paragraph.RemoveChild($child)
    }
  }
  $run = $Doc.CreateElement('w', 'r', $WNs)
  $textNode = $Doc.CreateElement('w', 't', $WNs)
  [void]$textNode.SetAttribute('space', 'http://www.w3.org/XML/1998/namespace', 'preserve')
  $textNode.InnerText = $Text
  [void]$run.AppendChild($textNode)
  [void]$Paragraph.AppendChild($run)
}

function Set-CellText($Cell, [string]$Text) {
  $children = @($Cell.ChildNodes)
  foreach ($child in $children) {
    if ($child.LocalName -ne 'tcPr') {
      [void]$Cell.RemoveChild($child)
    }
  }
  $paragraph = $Doc.CreateElement('w', 'p', $WNs)
  [void]$Cell.AppendChild($paragraph)
  Set-ParagraphText $paragraph $Text
}

function Set-RowText($Row, [string[]]$Values) {
  $cells = @($Row.SelectNodes('./w:tc', $Ns))
  for ($i = 0; $i -lt [Math]::Min($cells.Count, $Values.Count); $i++) {
    Set-CellText $cells[$i] $Values[$i]
  }
}

function New-TextParagraph([string]$Text, [bool]$Bold = $false) {
  $paragraph = $Doc.CreateElement('w', 'p', $WNs)
  $run = $Doc.CreateElement('w', 'r', $WNs)
  if ($Bold) {
    $rPr = $Doc.CreateElement('w', 'rPr', $WNs)
    [void]$rPr.AppendChild($Doc.CreateElement('w', 'b', $WNs))
    [void]$run.AppendChild($rPr)
  }
  $textNode = $Doc.CreateElement('w', 't', $WNs)
  [void]$textNode.SetAttribute('space', 'http://www.w3.org/XML/1998/namespace', 'preserve')
  $textNode.InnerText = $Text
  [void]$run.AppendChild($textNode)
  [void]$paragraph.AppendChild($run)
  return $paragraph
}

function Replace-ParagraphContaining([string]$Needle, [string]$Replacement) {
  foreach ($paragraph in @($Doc.SelectNodes('//w:body//w:p', $Ns))) {
    if ((Get-NodeText $paragraph).Contains($Needle)) {
      Set-ParagraphText $paragraph $Replacement
      return $true
    }
  }
  return $false
}

function Fmt([object]$Value, [int]$Digits = 2) {
  if ($null -eq $Value) { return '' }
  $number = [double]$Value
  return $number.ToString("F$Digits", [Globalization.CultureInfo]::InvariantCulture)
}

$Sc = $Summary.seaCucumber.descriptive
$WeightImta = $Sc | Where-Object { $_.Parameter -eq 'Body Weight (g)' -and $_.Treatment -eq 'IMTA' } | Select-Object -First 1
$WeightMono = $Sc | Where-Object { $_.Parameter -eq 'Body Weight (g)' -and $_.Treatment -eq 'Monoculture' } | Select-Object -First 1
$LengthImta = $Sc | Where-Object { $_.Parameter -eq 'Body Length (cm)' -and $_.Treatment -eq 'IMTA' } | Select-Object -First 1
$LengthMono = $Sc | Where-Object { $_.Parameter -eq 'Body Length (cm)' -and $_.Treatment -eq 'Monoculture' } | Select-Object -First 1
$SeaweedReps = @($Summary.seaweed.summary | Where-Object { $_.Replicate -ne 'Overall' })
$SeaweedOverall = $Summary.seaweed.summary | Where-Object { $_.Replicate -eq 'Overall' } | Select-Object -First 1
$Anova = $Summary.seaweed.anova

# Insert a reproducible Material and Methodology study-area section before Results.
$Body = $Doc.SelectSingleNode('//w:body', $Ns)
$ResultsNode = $null
foreach ($child in @($Body.ChildNodes)) {
  if ($child.LocalName -eq 'p' -and (Get-NodeText $child).Trim() -eq '3. Results') {
    $ResultsNode = $child
    break
  }
}
if (-not $ResultsNode) { throw 'Could not find the "3. Results" insertion point in result.docx.' }
foreach ($child in @($Body.ChildNodes)) {
  if ($child -eq $ResultsNode) { break }
  [void]$Body.RemoveChild($child)
}

[xml]$Rels = Get-Content -LiteralPath $RelationshipsPath -Raw
$RelNs = New-Object System.Xml.XmlNamespaceManager($Rels.NameTable)
$RelNs.AddNamespace('rel', 'http://schemas.openxmlformats.org/package/2006/relationships')
$existingStudyRel = $Rels.SelectSingleNode("//rel:Relationship[@Target='media/study_area_map.jpeg']", $RelNs)
if ($existingStudyRel) {
  $StudyRelId = $existingStudyRel.Id
} else {
  $maxRel = 0
  foreach ($rel in $Rels.Relationships.Relationship) {
    if ($rel.Id -match '^rId(\d+)$') { $maxRel = [Math]::Max($maxRel, [int]$Matches[1]) }
  }
  $StudyRelId = "rId$($maxRel + 1)"
  $newRel = $Rels.CreateElement('Relationship', 'http://schemas.openxmlformats.org/package/2006/relationships')
  [void]$newRel.SetAttribute('Id', $StudyRelId)
  [void]$newRel.SetAttribute('Type', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image')
  [void]$newRel.SetAttribute('Target', 'media/study_area_map.jpeg')
  [void]$Rels.DocumentElement.AppendChild($newRel)
}
$mediaDir = Join-Path $TempDir 'word\media'
New-Item -ItemType Directory -Path $mediaDir -Force | Out-Null
Copy-Item -LiteralPath $StudyMapPath -Destination (Join-Path $mediaDir 'study_area_map.jpeg') -Force
$Rels.Save($RelationshipsPath)

[xml]$ContentTypes = Get-Content -LiteralPath $ContentTypesPath -Raw
$CtNs = New-Object System.Xml.XmlNamespaceManager($ContentTypes.NameTable)
$CtNs.AddNamespace('ct', 'http://schemas.openxmlformats.org/package/2006/content-types')
if (-not $ContentTypes.SelectSingleNode("//ct:Default[@Extension='jpeg']", $CtNs)) {
  $default = $ContentTypes.CreateElement('Default', 'http://schemas.openxmlformats.org/package/2006/content-types')
  [void]$default.SetAttribute('Extension', 'jpeg')
  [void]$default.SetAttribute('ContentType', 'image/jpeg')
  [void]$ContentTypes.DocumentElement.AppendChild($default)
  $ContentTypes.Save($ContentTypesPath)
}

$ImageTemplate = $Doc.SelectSingleNode('//w:body//w:p[.//w:drawing]', $Ns)
if (-not $ImageTemplate) { throw 'Could not find an existing image paragraph to clone for the study-area map.' }
$StudyImageParagraph = $ImageTemplate.CloneNode($true)
$blips = @($StudyImageParagraph.GetElementsByTagName('blip', 'http://schemas.openxmlformats.org/drawingml/2006/main'))
foreach ($blip in $blips) {
  [void]$blip.SetAttribute('embed', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships', $StudyRelId)
}
$docPrs = @($StudyImageParagraph.GetElementsByTagName('docPr', 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing'))
$maxDocPr = 0
foreach ($docPr in $Doc.GetElementsByTagName('docPr', 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing')) {
  if ($docPr.id) { $maxDocPr = [Math]::Max($maxDocPr, [int]$docPr.id) }
}
foreach ($docPr in $docPrs) {
  [void]$docPr.SetAttribute('id', "$($maxDocPr + 1)")
  [void]$docPr.SetAttribute('name', 'Study Area Map')
}

$MethodNodes = @(
  (New-TextParagraph '2. Material and Methodology' $true),
  (New-TextParagraph '2.1 Area of Study' $true),
  (New-TextParagraph 'The sample collection and culture study area was located along the coastal waters of the Jaffna Peninsula, Sri Lanka, associated with the Palk Strait near Velanai/Thurayoor, Jaffna. The map reference provided for the sampling site shows approximately 9°40''01.6"N, 80°01''52.9"E (9.6671°N, 80.0314°E). The broader study area is within the northern coastal region of Sri Lanka, approximately 79.50°E-81.25°E and 9.25°N-10.00°N.' $false),
  $StudyImageParagraph,
  (New-TextParagraph 'Figure M1: Map reference showing the sample collection area near the Palk Strait, Jaffna Peninsula, Sri Lanka.' $true)
)
foreach ($node in $MethodNodes) {
  [void]$Body.InsertBefore($node, $ResultsNode)
}

$Tables = @($Doc.SelectNodes('//w:tbl', $Ns))
if ($Tables.Count -lt 6) { throw "Expected at least 6 tables; found $($Tables.Count)." }

# Table 2: sea cucumber descriptive statistics and Welch tests.
$Rows = @($Tables[1].SelectNodes('./w:tr', $Ns))
Set-RowText $Rows[1] @('Body Weight (g)', 'IMTA', "$($WeightImta.n)", (Fmt $WeightImta.Mean 3), (Fmt $WeightImta.SD 3), (Fmt $WeightImta.t 4), (Fmt $WeightImta.p 4), 'Not Significant')
Set-RowText $Rows[2] @('', 'Monoculture', "$($WeightMono.n)", (Fmt $WeightMono.Mean 3), (Fmt $WeightMono.SD 3), '', '', '(p > 0.05)')
Set-RowText $Rows[3] @('Body Length (cm)', 'IMTA', "$($LengthImta.n)", (Fmt $LengthImta.Mean 3), (Fmt $LengthImta.SD 3), (Fmt $LengthImta.t 4), (Fmt $LengthImta.p 4), 'Not Significant')
Set-RowText $Rows[4] @('', 'Monoculture', "$($LengthMono.n)", (Fmt $LengthMono.Mean 3), (Fmt $LengthMono.SD 3), '', '', '(p > 0.05)')

# Table 4: seaweed descriptive statistics.
$Rows = @($Tables[3].SelectNodes('./w:tr', $Ns))
for ($i = 0; $i -lt [Math]::Min(3, $SeaweedReps.Count); $i++) {
  $rep = $SeaweedReps[$i]
  Set-RowText $Rows[$i + 1] @($rep.Replicate, "$($rep.n)", (Fmt $rep.Mean_Weight_Gain_g 3), (Fmt $rep.SD_Weight_Gain_g 3), (Fmt $rep.SE_Weight_Gain_g 3))
}

# Table 5: ANOVA summary for seaweed weight gain.
$Rows = @($Tables[4].SelectNodes('./w:tr', $Ns))
Set-RowText $Rows[1] @('Between Groups', "$($Anova.dfBetween)", (Fmt $Anova.ssBetween 3), (Fmt $Anova.msBetween 3), (Fmt $Anova.f 4), (Fmt $Anova.p 4))
Set-RowText $Rows[2] @('Within Groups', "$($Anova.dfWithin)", (Fmt $Anova.ssWithin 3), (Fmt $Anova.msWithin 3), '', '')
Set-RowText $Rows[3] @('Total', "$([int]$Anova.dfBetween + [int]$Anova.dfWithin)", (Fmt ([double]$Anova.ssBetween + [double]$Anova.ssWithin) 3), '', '', '')

# Table 6: water quality summary.
$Rows = @($Tables[5].SelectNodes('./w:tr', $Ns))
$waterRows = @($Summary.waterQuality | Sort-Object Treatment, SampleWeek)
for ($i = 0; $i -lt [Math]::Min($waterRows.Count, $Rows.Count - 1); $i++) {
  $row = $waterRows[$i]
  Set-RowText $Rows[$i + 1] @(
    $row.Treatment,
    "$($row.SampleWeek)",
    (Fmt $row.pH 2),
    (Fmt $row.Salinity_ppt 2),
    (Fmt $row.TDS_ppt 2),
    (Fmt $row.Temperature_C 2),
    (Fmt $row.DO_mg_L 2),
    (Fmt $row.Conductivity_mS_cm 2)
  )
}

$figures = @(
  'Figure 1: Q-Q normality plots for Holothuria scabra body weight and body length in IMTA and Monoculture treatments.',
  'Figure 2: Comparative boxplots of Holothuria scabra body weight and body length between IMTA and Monoculture treatments.',
  'Figure 3: Mean Holothuria scabra body weight across the five recorded sampling weeks.',
  'Figure 4: Mean Holothuria scabra body length across the five recorded sampling weeks.',
  'Figure 5: Absolute Growth Rate (AGR) of Holothuria scabra between consecutive sampling intervals.',
  'Figure 6: Specific Growth Rate (SGR) of Holothuria scabra between consecutive sampling intervals.',
  'Figure 7: Survival rate of Kappaphycus alvarezii across the three seaweed replicates.',
  'Figure 8: Weight gain distribution of Kappaphycus alvarezii across seaweed replicates.',
  'Figure 9: Absolute Growth Rate (AGR) of Kappaphycus alvarezii across replicates.',
  'Figure 10: Specific Growth Rate (SGR) of Kappaphycus alvarezii across replicates.',
  'Figure 11: Mean seedling weight gain of Kappaphycus alvarezii across replicates.',
  'Figure 12: Q-Q plots for Kappaphycus alvarezii weight gain across replicates.',
  'Figure 13: Mean Total Dissolved Solids (TDS) in IMTA and Monoculture treatments.',
  'Figure 14: Mean pH levels in IMTA and Monoculture treatments.',
  'Figure 15: Mean salinity in IMTA and Monoculture treatments.',
  'Figure 16: Mean dissolved oxygen in IMTA and Monoculture treatments.',
  'Figure 17: Mean conductivity in IMTA and Monoculture treatments.',
  'Figure 18: Mean water temperature in IMTA and Monoculture treatments.',
  'Figure 19: Mean nitrite concentration in IMTA and Monoculture treatments at Week 3 and Week 7.',
  'Figure 20: Mean sodium nitrite concentration in IMTA and Monoculture treatments at Week 3 and Week 7.',
  'Figure 21: Mean nitrite nitrogen concentration in IMTA and Monoculture treatments at Week 3 and Week 7.',
  'Figure 22: Mean phosphorus concentration in IMTA and Monoculture treatments at Week 3 and Week 7.',
  'Figure 23: Mean phosphate concentration in IMTA and Monoculture treatments at Week 3 and Week 7.',
  'Figure 24: Mean phosphorus pentoxide concentration in IMTA and Monoculture treatments at Week 3 and Week 7.'
)

$captionIndex = 0
foreach ($paragraph in @($Doc.SelectNodes('//w:body//w:p', $Ns))) {
  $text = (Get-NodeText $paragraph).Trim()
  if ($text -match '^Figure\s*(\d+)?\s*:') {
    if ($captionIndex -lt $figures.Count) {
      Set-ParagraphText $paragraph $figures[$captionIndex]
      $captionIndex++
    }
  }
}

[void](Replace-ParagraphContaining 'Descriptive statistics indicated that individuals in the IMTA group reached slightly higher mean weights' "Descriptive statistics indicated that individuals in the IMTA group had higher mean body weight ($((Fmt $WeightImta.Mean 2)) +/- $((Fmt $WeightImta.SD 2)) g) and body length ($((Fmt $LengthImta.Mean 2)) +/- $((Fmt $LengthImta.SD 2)) cm) than the Monoculture group ($((Fmt $WeightMono.Mean 2)) +/- $((Fmt $WeightMono.SD 2)) g; $((Fmt $LengthMono.Mean 2)) +/- $((Fmt $LengthMono.SD 2)) cm). Welch's t-tests showed that these differences were not statistically significant (weight p = $((Fmt $WeightImta.p 4)); length p = $((Fmt $LengthImta.p 4))).")

[void](Replace-ParagraphContaining 'The boxplots compare the final body weight and body length' "The boxplots compare pooled body weight and body length observations for Holothuria scabra between IMTA and Monoculture treatments. The tests remained non-significant (weight p = $((Fmt $WeightImta.p 4)); length p = $((Fmt $LengthImta.p 4))), although the IMTA group showed higher mean values. The overlapping distributions and large standard deviations indicate that individual variability was high relative to the treatment difference.")

[void](Replace-ParagraphContaining 'Weekly monitoring revealed fluctuating growth trends over the five-week experimental period.' 'Weekly monitoring covered five recorded sea cucumber sampling weeks, corresponding to source workbook weeks 2 to 6. Sample sizes were unequal across weeks because the number of measured individuals changed over time; therefore, weekly trends should be interpreted as descriptive mean trajectories rather than repeated measurements of a fixed cohort.')

[void](Replace-ParagraphContaining 'Replicate 1 showed the highest mean weight gain' "Replicate 2 showed the highest mean weight gain ($((Fmt ($SeaweedReps | Where-Object { $_.Replicate -eq 'Replicate 2' } | Select-Object -ExpandProperty Mean_Weight_Gain_g) 2)) g), followed closely by Replicate 1, while Replicate 3 was lower. The one-way ANOVA found no statistically significant difference in weight gain among replicates (F = $((Fmt $Anova.f 4)), p = $((Fmt $Anova.p 4))).")

[void](Replace-ParagraphContaining 'The ANOVA results (F = 0.6375, p = 0.5311)' "The ANOVA results (F = $((Fmt $Anova.f 4)), p = $((Fmt $Anova.p 4))) indicate that mean seaweed weight gain did not differ significantly among replicates (p > 0.05), although Replicate 3 had the lowest descriptive biomass gain and survival.")

[void](Replace-ParagraphContaining 'The bar chart illustrates the changes in nitrite concentration' 'The bar chart illustrates changes in nitrite concentration (ug/L) between IMTA and Monoculture treatments at Week 3 and Week 7. IMTA decreased from 57.33 ug/L to 49.67 ug/L, while Monoculture decreased from 62.00 ug/L to 49.00 ug/L. Both systems therefore showed lower nitrite by Week 7, with Monoculture starting higher and ending slightly lower.')

[void](Replace-ParagraphContaining 'The bar chart illustrates the changes in sodium nitrite' 'The bar chart illustrates sodium nitrite (NaNO2) concentration (ug/L) in IMTA and Monoculture treatments at Week 3 and Week 7. IMTA decreased from 86.00 ug/L to 74.00 ug/L, while Monoculture decreased from 105.00 ug/L to 73.33 ug/L. The larger decline in Monoculture reflects its higher initial value.')

[void](Replace-ParagraphContaining 'The bar chart illustrates the changes in phosphorus (P) concentration' 'The bar chart illustrates phosphorus (P) concentration (ug/L) in IMTA and Monoculture treatments at Week 3 and Week 7. IMTA increased from 28.00 ug/L to 42.00 ug/L, whereas Monoculture decreased from 32.00 ug/L to 22.67 ug/L. This is the key nutrient contradiction: the current IMTA setup accumulated phosphorus rather than removing it.')

[void](Replace-ParagraphContaining 'By the end of the study, the Monoculture system recorded substantially higher mean phosphorus concentrations' 'By Week 7, IMTA recorded the higher mean phosphorus concentration (42.00 ug/L) compared with Monoculture (22.67 ug/L). This indicates phosphorus accumulation in the integrated system during the measured interval.')

[void](Replace-ParagraphContaining 'Overall, the findings suggest that the IMTA system was more effective in reducing and regulating phosphorus concentrations' 'Overall, the findings do not support the claim that the current IMTA setup was more effective at reducing phosphorus. The measured phosphorus and phosphate values increased in IMTA between Week 3 and Week 7, while both decreased in Monoculture. The most defensible conclusion is that the seaweed biomass or system ratio was insufficient for phosphorus removal during this experiment.')

[void](Replace-ParagraphContaining 'Overall, the findings suggest that the IMTA system experienced increased phosphate accumulation over time' 'Overall, the IMTA system experienced phosphate accumulation over time, increasing from 86.33 ug/L to 127.33 ug/L, while Monoculture decreased from 98.33 ug/L to 70.67 ug/L. This should be presented as a limitation of the current IMTA design rather than evidence of superior phosphate bio-filtration.')

[void](Replace-ParagraphContaining 'Overall, the data suggest that while the Monoculture system was more effective in reducing phosphorus levels over time' 'Overall, the data suggest that Monoculture reduced phosphorus compounds over the measured interval, while IMTA accumulated phosphorus compounds. This further confirms that the current seaweed density did not provide adequate phosphorus bio-filtration.')

$Settings = New-Object System.Xml.XmlWriterSettings
$Settings.Encoding = New-Object System.Text.UTF8Encoding($false)
$Settings.Indent = $false
$Writer = [System.Xml.XmlWriter]::Create($DocumentXmlPath, $Settings)
$Doc.Save($Writer)
$Writer.Close()

# Validate the edited XML before packaging.
[xml](Get-Content -LiteralPath $DocumentXmlPath -Raw) | Out-Null

$zipMode = [System.IO.Compression.ZipArchiveMode]::Create
$outZip = [System.IO.Compression.ZipFile]::Open($TempDocx, $zipMode)
try {
  foreach ($file in Get-ChildItem -LiteralPath $TempDir -Recurse -File) {
    $entryName = $file.FullName.Substring($TempDir.Length + 1).Replace('\', '/')
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($outZip, $file.FullName, $entryName) | Out-Null
  }
} finally {
  $outZip.Dispose()
}
Move-Item -LiteralPath $TempDocx -Destination $DocxPath -Force
Copy-Item -LiteralPath $DocxPath -Destination (Join-Path $WorkspaceDir 'result.docx') -Force
Remove-Item -LiteralPath $TempDir -Recurse -Force

Write-Output "Updated DOCX: $DocxPath"
Write-Output "Backup retained: $BackupPath"
Write-Output "Figure captions updated: $captionIndex"
