# Steps to build custom image in Powershell

Source: https://discuss.frappe.io/t/how-to-install-hrms-in-docker-version/105677/16

## 1. Prepare files

### `app.json`

```
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  },

  {
    "url": "https://github.com/frappe/hrms",
    "branch": "version-15"
  }
]
```

### `.env`

- Copy from `example.env`
  - Note that I set `DB_PASSWORD=admin`.
- Fill in the information below (adjust the information according to `[username]/[repo_name]`. Mine is `nnnpooh/erpnext`.)

```
CUSTOM_IMAGE='nnnpooh/erpnext'
CUSTOM_TAG='1.0.2'
```

### `nginx-entrypoint.sh`

- https://github.com/frappe/frappe_docker/issues/1292#issuecomment-2275703399
- Save on UTF8 and LF instead of CRLF.

## 2. Prepare Powershell session

- Inject variables into shell session
  - Adjust `$CUSTOM_IMAGE` and `$CUSTOM_TAG` accordingly.

```
$CUSTOM_IMAGE='nnnpooh/erpnext'
$CUSTOM_TAG='1.0.2'
$DOCKER_IMAGE_NAME=-join($CUSTOM_IMAGE,":",$CUSTOM_TAG)
$file_path="./app.json"
$content = Get-Content -Path $file_path -Raw
$byte_array = [System.Text.Encoding]::UTF8.GetBytes($content)
$APPS_JSON_BASE64 = [System.Convert]::ToBase64String($byte_array)
```

## 3. Build docker image

```
docker build `
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe `
  --build-arg=FRAPPE_BRANCH=version-15 `
  --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 `
  --tag=$DOCKER_IMAGE_NAME `
  --file=images/layered/Containerfile .
```

- Note that I used `--file-images/layered/Containerfile`, not `--file=images/custom/Containerfile`. This is faster to build.

## 4. Push to dockerhub

- Create repository in dockerhub with the name specified in `$CUSTOM_IMAGE`.
- `docker login`
- `docker push $DOCKER_IMAGE_NAME`

## 5.1: Manual installation

### 5.1.1 Prepare docker compose

```
docker compose -f compose.yaml `
  -f overrides/compose.mariadb.yaml `
  -f overrides/compose.redis.yaml `
  -f overrides/compose.noproxy.yaml `
  config > docker-compose-nr.yaml
```

### 5.1.2 Run

`docker compose -f docker-compose-nr.yaml up -d`

### 5.1.3 Manual installation

- Go into `backend` container
- `bench new-site --no-mariadb-socket --admin-password=admin --db-root-password=admin --install-app erpnext --set-default frontend`
  - Make sure the passwords are correct.
- `bench --site frontend install-app hrms`

## 5.2 Automatic installation

- I used docker compose from `https://github.com/vibeconn/erpnext-custom` and just changed the docker image to `nnnpooh/erpnext:1.0.2` and it works perfectly.
- You can just run it from `docker compose -f docker-compose-hrms.yaml up -d`.
  - Change the docker image as needed.

## 6. Remove (if needed)

- `docker compose -f docker-compose-nr.yaml down -v`
- `docker compose -f docker-compose-hrms.yaml down -v`
