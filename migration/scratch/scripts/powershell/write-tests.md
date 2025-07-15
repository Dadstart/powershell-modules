# Write-Tests

## Variables

```PowerShell
$num = 5
$ch = [char]'x'
$str = "Hello world!"
$arr = @('First', $str, $num)
$hash = @{
    "num" = $num
    "str" = $str
    "ch" = $ch
}
$psObj = [PSCustomObject]@{
    "num" = $num
    "str" = $str
    "ch" = $ch
}
$fileInfo = (Get-ChildItem -Path 'C:\' Windows -Directory)
```

| Variable | Value | Conclusion |
| -------- | ----- | ---------- |
| $num | 5 | Always value; except [object].ToString() |
| $ch | x | Always value, except [object].ToString() |
| $str | Hello World! | Always value |
| $arr | (First, Hello World!, 5 | Various forms. Write-Host breaks it up as an array, except [object].ToString() |
| $hash | [str, Hello world!] [ch, x] [num, 5] | Various forms. Write-Host breaks it up as an array of key/value pairs, except [object].ToString() |
| $psObj | @{num=5; str=Hello world!; ch=x} | Various forms. Write-Host has compact string. [object].ToString() fails |
| $fileInfo | (Get-ChildItem -Path 'C:\' Windows -Directory) | Various forms. \$fileInfo lists directory contents; Write-Host/ToString() writes out $fileInfo.FullName; [object].ToString() as expected |




## $num

### Conclusion
Always value, except [object].ToString()

#### $ob

```PowerShell
5

```

#### $obj.ToString()

```PowerShell
5

```

#### Write-Host $obj

```PowerShell
5

```

#### [object]$obj

```PowerShell
5

```

#### ([object]$obj).ToString()

```PowerShell
System.Int32

```

## $ch

### Conclusion
Always value, except [object].ToString()

#### $obj

```PowerShell
x

```

#### $obj.ToString()

```PowerShell
x

```

#### Write-Host $obj

```PowerShell
x

```

#### [object]$obj

```PowerShell
x

```

#### ([object]$obj).ToString()

```PowerShell
System.String

```

## $str

### Conclusion
Always value

#### $obj

```PowerShell
Hello world!

```

#### $obj.ToString()

```PowerShell
Hello world!

```

#### Write-Host $obj

```PowerShell
Hello world!

```

#### [object]$obj

```PowerShell
Hello world!

```

## $arr

### Conclusion
Various forms. Write-Host breaks it up as an array, except [object].ToString()

#### $obj

```PowerShell
First
Hello world!
5

```

#### $obj.ToString()

```PowerShell
System.Object[]

```

#### Write-Host $obj

```PowerShell
First Hello world! 5

```

#### [object]$obj

```PowerShell
First
Hello world!
5

```

#### ([object]$obj).ToString()

```PowerShell
System.Object[]

```

## $hash

### Conclusion
Various forms. Write-Host breaks it up as an array of key/value pairs, except [object].ToString()

#### $obj

```PowerShell

Name                           Value
----                           -----
str                            Hello world!
ch                             x
num                            5


```

#### $obj.ToString()

```PowerShell
System.Collections.Hashtable

```

#### Write-Host $obj

```PowerShell
[str, Hello world!] [ch, x] [num, 5]

```

#### [object]$obj

```PowerShell

Name                           Value
----                           -----
str                            Hello world!
ch                             x
num                            5


```

## $psObj

### Conclusion
Various forms. Write-Host has compact string. [object].ToString() fails

#### $obj

```PowerShell

num str          ch
--- ---          --
  5 Hello world! x


```

#### $obj.ToString()

```PowerShell


```

#### Write-Host $obj

```PowerShell
@{num=5; str=Hello world!; ch=x}

```

#### [object]$obj

```PowerShell

num str          ch
--- ---          --
  5 Hello world! x


```

#### ([object]$obj).ToString()

```PowerShell


```

## $fileInfo

### Conclusion
Various forms. $obj lists directory contents; Write-Host/ToString() writes out $fileInfo.FullName; [object].ToString() as expected

#### $obj

```PowerShell

    Directory: C:\

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----            7/8/2025  4:14 PM                Windows


```

#### $obj.ToString()

```PowerShell
C:\Windows

```

#### Write-Host $obj

```PowerShell
C:\Windows

```

#### [object]$obj

```PowerShell

    Directory: C:\

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----            7/8/2025  4:14 PM                Windows


```

#### ([object]$obj).ToString()

```PowerShell
System.IO.DirectoryInfo

```
