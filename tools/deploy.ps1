$env:Path += ";C:\Program Files\GitHub CLI"
gh workflow run "Deploy to GitHub Pages" --repo maxarvan/GameAsPresent
Write-Host "Triggered. Track progress with: gh run watch --repo maxarvan/GameAsPresent"
Write-Host "Live at: https://maxarvan.github.io/GameAsPresent/"
