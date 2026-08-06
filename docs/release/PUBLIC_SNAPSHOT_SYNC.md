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

## Release tags

In snapshot mode, do not push a tag created in the private repository because that tag would expose the private commit ancestry. Create the tag on the public repository's sync commit when preparing a public Release, or use the public Release page's generated tag.

## Remaining legal step

Add a project license before inviting outside contributors. The code and visual assets need an explicit license choice; MIT and Apache-2.0 are common options, but the repository owner must choose one.
