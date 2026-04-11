# GitHub Trending Daily Reports

🔥 AI-generated daily reports of newly trending GitHub projects.

## How It Works

1. A **cron job** runs `run.sh` every day at 8:00 AM CST
2. `run.sh` invokes **GitHub Copilot CLI** with a prompt (`prompt.md`)
3. Copilot CLI fetches the [GitHub Trending](https://github.com/trending) page
4. Filters out previously seen repos (tracked in `data/seen_repos.json`)
5. For each **new** repo, generates a rich AI introduction
6. Creates an HTML report in `reports/`
7. Updates `index.html` and pushes to GitHub
8. **GitHub Pages** auto-deploys the updated site

## Setup

1. Clone this repo
2. Ensure `copilot` CLI is installed and authenticated
3. Configure git push credentials (SSH key or token)
4. Add cron job:
   ```bash
   crontab -e
   # Add this line:
   0 8 * * * /mnt/disk1/zy/github_trend/run.sh >> /mnt/disk1/zy/github_trend/cron.log 2>&1
   ```
5. Enable GitHub Pages in repo settings (deploy from `main` branch via Actions)

## Manual Run

```bash
./run.sh
```

Or run the Copilot CLI directly:
```bash
copilot -p "$(cat prompt.md)"
```

## Project Structure

```
├── prompt.md            # Copilot CLI skill/prompt (core logic)
├── run.sh               # Cron-callable shell script
├── style.css            # Shared CSS for all pages
├── index.html           # Landing page listing all reports
├── data/
│   └── seen_repos.json  # Tracks previously reported repos
├── reports/             # Daily HTML reports
└── .github/workflows/
    └── pages.yml        # GitHub Pages deploy workflow
```
