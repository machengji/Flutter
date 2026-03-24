# maintenance_assistant

Flutter maintenance assistant app with mobile and web support.

## Local web build

Run the web build from the project directory:

```bash
flutter build web --release --base-href /Flutter/
```

The generated site will be written to `build/web`.

## GitHub Pages deployment

This repository contains a GitHub Actions workflow that builds the app from
`maintenance_assistant` and deploys it to GitHub Pages.

Expected site URL:

```text
https://machengji.github.io/Flutter/
```

If this is the first deployment, open the repository on GitHub and make sure:

1. `Settings -> Pages -> Build and deployment -> Source` is set to `GitHub Actions`.
2. The default branch is still `master`, because the workflow listens to pushes on `master`.

After that, every push that changes files under `maintenance_assistant/` will
trigger a fresh web build and publish the latest version automatically.
