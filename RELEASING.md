# Publishing an IQ Trader release

Source repository: `johntest811/IQ_Optios_Project` (private). Application repository: `johntest811/IQ_Optios_Project_Application` (public). Keep credentials, journals, configuration with user data, runtime files and virtual environments out of both.

1. Increment `trader.paths.VERSION` using `major.minor.patch`; update docs and validation.
2. Run unit tests, then `python build_app.py` in the configured Windows build environment. Inspect `dist/packaged-check.json` and test the installer.
3. Commit the reviewed source backup. Publish a stable GitHub release in the application repository with tag exactly `vVERSION` (not a prerelease).
4. Attach `dist/IQTrader-Setup.exe` and `dist/IQTrader-VERSION-update.zip`. GitHub supplies a SHA-256 asset digest through its releases API. Keep that exact update ZIP name.
5. Verify the publicly served release assets and digest. Run the app's update check from the preceding version. Installation must preserve user data, use a new version directory and leave trading off.

The release digest and per-file manifest provide transport/content integrity, not independent publisher signing. Do not overwrite an already published version; publish a new version. Existing 0.3.1 installations require one manual 0.4.0 install to acquire GitHub updating. Subsequent versions can use the in-app updater.

GitHub release API documentation: https://docs.github.com/en/rest/releases/releases .
