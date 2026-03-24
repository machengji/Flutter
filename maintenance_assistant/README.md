# maintenance_assistant

Flutter maintenance assistant app with mobile and web support.

## Local web build

Run the web build from the project directory:

```bash
flutter build web --release --base-href /Flutter/
```

The generated site will be written to `build/web`.

## GitHub Pages deployment

This repository uses the static files in the root `docs/` directory for GitHub
Pages deployment.

Expected site URL:

```text
https://machengji.github.io/Flutter/
```

To publish the latest web version:

1. Build the web app with `flutter build web --release --base-href /Flutter/`.
2. Sync `build/web` into the repository root `docs/` directory.
3. Commit and push the updated `docs/` files.

There is also a helper script in the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish-maintenance-web.ps1
```

If this is the first deployment, open the repository on GitHub and make sure:

1. `Settings -> Pages -> Build and deployment -> Source` is set to `Deploy from a branch`.
2. `Branch` is set to `master` and the folder is set to `/docs`.
