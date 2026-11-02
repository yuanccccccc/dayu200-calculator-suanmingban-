@echo off
@rem ---------------------------------------------------------------------------
@rem hvigor wrapper for the OpenHarmony 6.1.1-LTS (API 23) project.
@rem The hvigor engine is pinned in package.json and installed into .\node_modules
@rem (the old hvigor-wrapper.js only understands hvigorVersion 2.x and cannot run
@rem  this project's modelVersion 6.0.0 configuration).
@rem
@rem   npm install
@rem   hvigorw.bat assembleHap --mode module -p product=default --no-daemon
@rem
@rem 'java' (JDK 8+/17) must be available for the PackageHap task.
@rem ---------------------------------------------------------------------------
setlocal
set APP_HOME=%~dp0
for %%i in ("%APP_HOME%") do set APP_HOME=%%~fi

if defined NODE_HOME (
  set NODE_EXE=%NODE_HOME%\node.exe
) else (
  set NODE_EXE=node.exe
)

if not exist "%APP_HOME%\node_modules\@ohos\hvigor\bin\hvigor.js" (
  echo ERROR: hvigor is not installed ^(node_modules\@ohos\hvigor missing^).
  echo Run "npm install" in %APP_HOME% first ^(see README.md^).
  exit /b 1
)

"%NODE_EXE%" "%APP_HOME%\node_modules\@ohos\hvigor\bin\hvigor.js" %*
