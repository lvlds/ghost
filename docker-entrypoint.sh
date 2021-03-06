#!/bin/bash
set -e

chown -R user /usr/src/ghost/content/

# allow the container to be started with `--user`
if [[ "$*" == npm*start* ]] && [ "$(id -u)" = '0' ]; then
	chown -R user "$GHOST_CONTENT"
	exec gosu user "$BASH_SOURCE" "$@"
fi

if [[ "$*" == npm*start* ]]; then
	baseDir="$GHOST_SOURCE/content"
	for dir in "$baseDir"/*/ "$baseDir"/themes/*/; do
		targetDir="$GHOST_CONTENT/${dir#$baseDir/}"
		mkdir -p "$targetDir"
		if [ -z "$(ls -A "$targetDir")" ]; then
			tar -c --one-file-system -C "$dir" . | tar xC "$targetDir"
		fi
	done

	if [ -z "$GHOST_CONFIG_SECRET" ]; then
		if [ ! -e "$GHOST_CONTENT/config.js" ]; then
			sed -r '
				s/127\.0\.0\.1/0.0.0.0/g;
				s!path.join\(__dirname, (.)/content!path.join(process.env.GHOST_CONTENT, \1!g;
			' "$GHOST_SOURCE/config.example.js" > "$GHOST_CONTENT/config.js"
		fi
	else
		echo "Using configuration from Kubernetes Secret"
		cp -f "$GHOST_CONFIG_SECRET" $GHOST_CONTENT/config.js;
	fi
fi

exec "$@"
