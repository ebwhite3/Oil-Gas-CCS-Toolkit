@echo off
REM ---------------------------------------------------------------------------
REM serve.bat - Serve the NSLLC Petroleum Toolkit on the local network.
REM
REM Serves THIS folder (the location of this script) so the toolkit is reachable
REM on the LAN at:  http://10.66.1.10:8000/oil-gas-ccs-toolkit.html
REM
REM Because it serves its own directory (%~dp0), this keeps working even if the
REM toolkit folder is moved or renamed again - just keep serve.bat alongside
REM oil-gas-ccs-toolkit.html. Bind 0.0.0.0 exposes it to other machines on the
REM LAN; use --bind 127.0.0.1 instead if you want it reachable only locally.
REM ---------------------------------------------------------------------------
cd /d "%~dp0"
echo Serving "%~dp0"
echo Open: http://10.66.1.10:8000/oil-gas-ccs-toolkit.html
python -m http.server 8000 --bind 0.0.0.0
