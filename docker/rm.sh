#!/bin/bash

#!/bin/bash

set -a

SETTINGS="$1"
source ${SETTINGS}

cd ${WEBSITE_DIR}
docker-compose rm

set +a
