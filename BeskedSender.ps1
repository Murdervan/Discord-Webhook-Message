Add-Type -AssemblyName System.Windows.Forms

# Skjul den sorte konsol
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("User32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

public static void HideConsole() {
    IntPtr hWnd = GetConsoleWindow();
    if (hWnd != IntPtr.Zero) {
        ShowWindow(hWnd, 0); // 0 = SW_HIDE
    }
}
'
[Console.Window]::HideConsole()

# Funktion til at sende besked
function Send-Message {
    param (
        [string]$Service,
        [string]$WebhookOrToken,
        [string]$ChatID,
        [string]$Message
    )

    if (-not $WebhookOrToken -or (-not $ChatID -and $Service -eq "Telegram")) {
        [System.Windows.Forms.MessageBox]::Show("Webhook URL, Telegram Token eller Chat ID mangler!", "Fejl", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $json = @{
        content = $Message
    } | ConvertTo-Json

    if ($Service -eq "Discord") {
        $null = Invoke-RestMethod -Uri $WebhookOrToken -Method Post -Body $json -ContentType "application/json"
        [System.Windows.Forms.MessageBox]::Show("Besked sendt til Discord!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    elseif ($Service -eq "Telegram") {
        $telegramURL = "https://api.telegram.org/bot$WebhookOrToken/sendMessage?chat_id=$ChatID"
        $null = Invoke-RestMethod -Uri $telegramURL -Method Post -Body $json -ContentType "application/json"
        [System.Windows.Forms.MessageBox]::Show("Besked sendt til Telegram!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
}

# Opretter GUI-vinduet
$form = New-Object System.Windows.Forms.Form
$form.Text = "Besked Sender"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"
$form.Topmost = $true

# Tilføjer "MADE BY @Murdervan - github.com/Murdervan" øverst
$creditLabel = New-Object System.Windows.Forms.Label
$creditLabel.Text = "MADE BY @Murdervan - github.com/Murdervan"
$creditLabel.Location = New-Object System.Drawing.Point(10, 10)
$creditLabel.AutoSize = $true
$form.Controls.Add($creditLabel)

# Label for dropdown menu
$serviceLabel = New-Object System.Windows.Forms.Label
$serviceLabel.Text = "Vælg Service:"
$serviceLabel.Location = New-Object System.Drawing.Point(10, 40)
$serviceLabel.AutoSize = $true
$form.Controls.Add($serviceLabel)

# Dropdown menu for valg af service
$serviceComboBox = New-Object System.Windows.Forms.ComboBox
$serviceComboBox.Location = New-Object System.Drawing.Point(150, 40)
$serviceComboBox.Size = New-Object System.Drawing.Size(200, 20)
$serviceComboBox.Items.AddRange(@("Discord", "Telegram"))
$form.Controls.Add($serviceComboBox)

# Label for Webhook URL eller Token
$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Text = "Indtast Webhook URL eller Telegram Token:"
$inputLabel.Location = New-Object System.Drawing.Point(10, 70)
$inputLabel.AutoSize = $true
$form.Controls.Add($inputLabel)

# Textbox til indtastning af webhook URL eller token
$inputTextBox = New-Object System.Windows.Forms.TextBox
$inputTextBox.Location = New-Object System.Drawing.Point(10, 100)
$inputTextBox.Size = New-Object System.Drawing.Size(560, 20)
$form.Controls.Add($inputTextBox)

# Label for Telegram Chat ID
$chatIDLabel = New-Object System.Windows.Forms.Label
$chatIDLabel.Text = "Indtast Telegram Chat ID (kun for Telegram):"
$chatIDLabel.Location = New-Object System.Drawing.Point(10, 130)
$chatIDLabel.AutoSize = $true
$form.Controls.Add($chatIDLabel)

# Textbox til indtastning af Telegram Chat ID
$chatIDTextBox = New-Object System.Windows.Forms.TextBox
$chatIDTextBox.Location = New-Object System.Drawing.Point(10, 160)
$chatIDTextBox.Size = New-Object System.Drawing.Size(560, 20)
$form.Controls.Add($chatIDTextBox)

# Label for Besked
$messageLabel = New-Object System.Windows.Forms.Label
$messageLabel.Text = "Indtast Besked:"
$messageLabel.Location = New-Object System.Drawing.Point(10, 190)
$messageLabel.AutoSize = $true
$form.Controls.Add($messageLabel)

# Textbox til indtastning af besked (større)
$messageTextBox = New-Object System.Windows.Forms.TextBox
$messageTextBox.Location = New-Object System.Drawing.Point(10, 220)
$messageTextBox.Size = New-Object System.Drawing.Size(560, 150)
$messageTextBox.Multiline = $true
$form.Controls.Add($messageTextBox)

# Knappen til at sende besked
$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Location = New-Object System.Drawing.Point(250, 380)
$sendButton.Size = New-Object System.Drawing.Size(100, 30)
$sendButton.Text = "Send Besked"
$form.Controls.Add($sendButton)

# Funktion til at håndtere klik på send-knappen
$sendButton.Add_Click({
    $service = $serviceComboBox.SelectedItem
    $webhookOrToken = $inputTextBox.Text
    $chatID = $chatIDTextBox.Text
    $message = $messageTextBox.Text

    Send-Message -Service $service -WebhookOrToken $webhookOrToken -ChatID $chatID -Message $message
})

# Funktion til at skjule og minimere formen til proceslinjen
$form.Add_Shown({
    $form.WindowState = "Normal"
    $form.ShowInTaskbar = $true
})

# Funktion til at lukke PowerShell-vinduet når GUI lukkes
$form.Add_FormClosed({
    [Console.Window]::CloseConsole()
})

# Viser GUI
$form.ShowDialog() | Out-Null

# Vent på brugerinput inden scriptet afsluttes
Write-Host "Tryk på Enter for at afslutte..."
Read-Host
