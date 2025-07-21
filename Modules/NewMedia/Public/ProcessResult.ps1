class ProcessResult {
    <#
    .SYNOPSIS
        Represents the result of a process execution.
    .DESCRIPTION
        This class encapsulates the output, error, and exit code from a process execution.
        It provides a standardized way to handle process results across the module.
    .PROPERTY Output
        The standard output from the process as a string.
    .PROPERTY Error
        The standard error output from the process as a string.
    .PROPERTY ExitCode
        The exit code returned by the process as an integer.
    .EXAMPLE
        $result = Invoke-Process 'ffprobe' @('-version')
        if ($result.ExitCode -eq 0) {
            Write-Host "Process succeeded: $($result.Output)"
        } else {
            Write-Error "Process failed: $($result.Error)"
        }
    .NOTES
        This class is used by Invoke-Process and related functions to provide
        consistent return types for process execution results.
    #>
    # Properties
    [string]$Output
    [string]$Error
    [int]$ExitCode

    # Constructor
    ProcessResult([string]$ProcessOutput, [string]$ProcessError, [int]$ProcessExitCode) {
        $this.Output = $ProcessOutput
        $this.Error = $ProcessError
        $this.ExitCode = $ProcessExitCode
    }

    # Method to check if the process succeeded
    [bool]get_Success() {
        return $this.ExitCode -eq 0
    }

    # Method to check if the process failed
    [bool]get_Failure() {
        return $this.ExitCode -ne 0
    }

    [PSObject]ToJson(
        [int]$Depth = 10
    ) {
        return $this.Output | ConvertFrom-Json -Depth $Depth
    }

    [PSObject]ToXml() {
        # Create XML document
        $doc = New-Object System.Xml.XmlDocument

        # Create root element
        $root = $doc.CreateElement('ProcessResult')
        $doc.AppendChild($root)

        # Dynamically add child elements for each key property
        foreach ($prop in @('Output', 'Error', 'ExitCode')) {
            $node = $doc.CreateElement($prop)
            $node.InnerText = $this.$prop
            $root.AppendChild($node)
        }

        # Include derived properties
        $successNode = $doc.CreateElement('Success')
        $successNode.InnerText = $this.Succeeded
        $root.AppendChild($successNode)
        $failureNode = $doc.CreateElement('Failure')
        $failureNode.InnerText = $this.Failure
        $root.AppendChild($failureNode)

        # Return structured object containing XML as string and DOM
        return [PSCustomObject]@{
            Xml       = $doc.OuterXml      # Raw XML string
            XmlObject = $doc               # DOM for XPath or advanced use
        }
    }

    # Override ToString method for better debugging
    [string]ToString() {
        return "ProcessResult [Success=$($this.Success)]; Output: $(this.Output?.Length) bytes; Error: ($(this.Error?.Length)) bytes"
    }
}
