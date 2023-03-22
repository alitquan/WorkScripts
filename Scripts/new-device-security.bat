@ECHO OFF
ECHO Setting Security Policies...
net accounts
net accounts /maxpwage:90
net accounts /minpwlen:10
net accounts /uniquepw:5
net accounts
reg add HKLM\SYSTEM\CurrentControlSet\Services\UsbStor /v "Start" /t REG_DWORD /d "4" /f 
PAUSE