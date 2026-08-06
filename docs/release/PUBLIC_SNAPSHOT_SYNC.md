# Private to public snapshot sync

The private `CountdownCalendar` repository is the only development source. The public `Until` repository is a distribution mirror.

The two repositories currently have unrelated histories. Use the snapshot workflow so private commits are never pushed to the public repository.

## Preview

```powershell
cd D:\personal\CountdownCalendar
.\scripts\publish_public_snapshot.ps1
```

The script runs the full tracked-file guard, exports only the current `main` tree with `git archive`, clones the public `main` into a temporary directory, and shows the exact public changes. It does not push by default.

## Publish

After reviewing the listed changes:

```powershell
.\scripts\publish_public_snapshot.ps1 -Publish
```

The public repository receives a normal commit such as `sync: publish private snapshot 0e8b24e`. The private commit history, ignored signing files, keystore, and local properties are not copied.

The private-only `publish-public.yml` workflow is intentionally excluded from public snapshots, so the public mirror does not try to publish itself without the private token.

## Release tags

In snapshot mode, do not push a tag created in the private repository because that tag would expose the private commit ancestry. Create the tag on the public repository's sync commit when preparing a public Release, or use the public Release page's generated tag.

## Automatic mode

The private repository also contains `.github/workflows/publish-public.yml`. After it is enabled, every push to private `main` automatically publishes a safe snapshot to public `Until/main`; the workflow never pushes private Git history.

Create a GitHub fine-grained personal access token with **Contents: Read and write** permission limited to the `wdlami/Until` repository. Add it in the private repository under **Settings → Secrets and variables → Actions** as:

```text
PUBLIC_REPO_TOKEN
```

The token is read only by the workflow and is not stored in the repository. You can also start a one-off publication from **Actions → Publish public snapshot → Run workflow**.

The source code is licensed under MIT. Until/待到 names, icons, screenshots, and other brand assets are not included in that code license; third-party dependencies remain under their own licenses.
