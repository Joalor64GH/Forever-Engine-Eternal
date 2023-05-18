curl -# -O https://download.visualstudio.microsoft.com/download/pr/5c9aef4f-a79b-4b72-b379-14273860b285/58398a76f32a0149d38fba79bbf71b6084ccd4200ea665bf2bcd954cdc498c7f/vs_Community.exe
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.20348
del vs_Community.exe
exit