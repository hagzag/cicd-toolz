# CI🌩️CD-Toolz - Docker Image

<!-- vscode-markdown-toc -->
* 1. [Introduction](#Introduction)
* 2. [ Tools included](#Toolsincluded)
	* 2.1. [semantic releae overview](#semanticreleaeoverview)
* 3. [How to use GitLab](#HowtouseGitLab)
* 4. [How to use GitHub](#HowtouseGitHub)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

## 1. <a name='Introduction'></a>Introduction

This image is a containerization of common sools used during build such as semantic-release, helm, kubectl, kubectx & kubens - this can also be used by the developer team to mount and execute any command contained in the container.

---

## 2. <a name='Toolsincluded'></a> Tools included

* `semantic-release` -  Inspects commits messages and automatically creates/pushes tags in SemVer format back to the repo.

* `sematic-rlease plugins` - a set of plugins used to release e.g
  
  ```yml
    semantic-release 
    @semantic-release/git 
    @semantic-release/gitlab 
    @semantic-release/github 
    @semantic-release/release-notes-generator 
    @semantic-release/commit-analyzer 
    @semantic-release/changelog 
    @semantic-release/exec
    # --- (not covered in this project)
    # semantic-release-docker  
    # semantic-release-helm 
    # semantic-release-helm3 
    # ---
  ```

* `yq` - `yml` query & editing comman line tool
* `jq` - `json` query & editing comman line tool
* ...

### 2.1. <a name='semanticreleaeoverview'></a>semantic releae overview

* Developer commits code with commit messages following Angular's conventional commits spec.
* Tool inspects commit messages as code gets merged and does the following:
  * Generates a git tag following the Semver spec, while inferring from the commit message.
  * Pushes generated tag back to repo.
  * Generates Gitlab release notes

| Commit message                                                                                                                                                                                 | Release type               |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------- |
| `fix(pencil): stop graphite breaking when too much pressure applied`                                                                                                                             | Patch Release              |
| `feat(pencil): add 'graphiteWidth' option`                                                                                                                                                       | ~~Minor~~ Feature Release  |
| `perf(pencil): remove graphiteWidth option`<br><br>`BREAKING CHANGE: The graphiteWidth option has been removed.`<br>`The default graphite width of 10mm is always used for performance reasons.` | ~~Major~~ Breaking Release |

## 3. <a name='HowtouseGitLab'></a>How to use GitLab

1. Ensure you have .releasesrc.yml in the root of your project. \
   See here for more details on configuration [Semantic Release Configuration](https://github.com/semantic-release/semantic-release/blob/master/docs/usage/configuration.md#configuration) \
   The basic configuration below watches for merges to "master" branch

```yml
---
branches:
- master
plugins:
- - "@semantic-release/gitlab"
  - gitlabUrl: https://gitlab.com
- - "@semantic-release/release-notes-generator"
  - {}
```

<!-- ```json
{
  "branches": [ "master" ],
  "plugins": [
    ["@semantic-release/gitlab", {
      "gitlabUrl": "https://gitlab.com"
    }],
    ["@semantic-release/release-notes-generator", {}]
  ]
}
``` -->

1. Configure your gitlab ci pipeline to use Semantic Release example `.gitlab-ci.yml`

```yaml
stages:
  - release

release:
  - image: registry.gitlab.com/hagzag/semantic-release-docker:latest
  - script:
      - semantic-release
```

1. Set environment variable `GITLAB_TOKEN` (or GL_TOKEN) to be the access token with push permissions to your repo.

## 4. How to use GitHub

* Same as above replace `GITLAB_TOKEN` with `GITHUB_TOKEN` (or GH_TOKEN)
* `.releaserc.yml` which in gihub this case would look like so:

    ```yml
    branches:
    - main
    plugins:
    - "@semantic-release/commit-analyzer"
    - "@semantic-release/release-notes-generator"
    - "@semantic-release/github"
    - - "@semantic-release/exec"
    - verifyReleaseCmd: echo \${nextRelease.version} > nextVersion
    ```

This means we need all these npm packages to install each time ... hence this project ;) which cab build a container with all these inside ... (without talking sides ... `GH` / `GL`)

<details>
  <summary><b>Which should yield somthing similar to this:</b></summary>

```yml

# An example github-actions.yml

# This is a basic workflow to help you get started with Actions

name: release-flow

# Controls when the workflow will run
on:
  # Triggers the workflow on push or pull request events but only for the "main" branch
  push:
    branches: [ "*" ]
  pull_request:
    branches: [ "main" ]

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

# A workflow run is made up of one or more jobs that can run sequentially or in parallel
jobs:
  # This workflow contains a single job called "build"
  build:
    # The type of runner that the job will run on
#     runs-on: ubuntu-latest
    runs-on: [self-hosted] 
    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
      # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
      - uses: actions/checkout@v3

      - uses: actions/setup-node@v3
        with:
          node-version: 18

      - name: Install semantic releae dependencies
        run: |
          npm install -g semantic-release
          npm install -g @semantic-release/git @semantic-release/github @semantic-release/changelog @semantic-release/commit-analyzer @semantic-release/release-notes-generator @semantic-release/exec

      - name: Get npm cache directory
        id: npm-cache-dir
        shell: bash
        run: echo "dir=$(npm config get cache)" >> ${GITHUB_OUTPUT}

      - name: setup and execute semantic-release
        id: nextrealease
        run: |
          cat <<EOF>> .releaserc.yml
          branches:
          - main
          plugins:
          - "@semantic-release/commit-analyzer"
          - "@semantic-release/release-notes-generator"
          - "@semantic-release/github"
          - - "@semantic-release/exec"
            - verifyReleaseCmd: echo \${nextRelease.version} > nextVersion
          EOF
          semantic-release -r ${{ github.server_url }}/${{ github.repository }}.git
          test -f nextVersion && echo "SRTAG=v$(cat nextVersion)" >> ${GITHUB_OUTPUT}
          cat nextVersion
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          
      - name: just echo nectVerson
        run: echo $SRTAG
        env:
          SRTAG: ${{ steps.nextrealease.outputs.SRTAG }}
```

</details>

### Controbuting - welcome to PR additional tools

Please considet the weight this tool adds too the system and in some cases may use a different image for different tooling - this one was served to be an all in one slim container which is almost `~250MG` :woman_with_turban: mcuah more than initially expected - but that's life.